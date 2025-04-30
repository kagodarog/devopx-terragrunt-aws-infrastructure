locals {
  tags = {
    env_prefix = var.env_prefix
    project    = "devopx"
  }
}

resource "random_string" "db_name_suffix" {
  length  = 5
  special = false
  upper   = false
  lower   = true
}


resource "aws_db_subnet_group" "rds-mysql" {
  name        = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-mysql-subnet-gp-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-mysql-subnet-gp"
  subnet_ids  = var.private_subnets
  description = "db-subnet-group"
  tags = {
    Name : var.create_prod_instance ? "de-${local.tags.env_prefix}-db-subnet-group-${random_string.db_name_suffix.result}" : "de-${local.tags.env_prefix}-db-subnet-group"
  }
}

resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "_%][?"
}

resource "aws_db_parameter_group" "default" {
  family      = "mysql8.0"
  name        = var.create_prod_instance ? "devopx-pg-custom-${random_string.db_name_suffix.result}" : "devopx-pg-custom"
  description = "Custom parameter group for MySQL 8.0"
  tags = {
    Name = var.create_prod_instance ? "de-${local.tags.env_prefix}-pg-custom-${random_string.db_name_suffix.result}" : "de-${local.tags.env_prefix}-pg-custom"
  }

  dynamic "parameter" {
    for_each = var.rds.db_custom_param
    content {
      apply_method = try(parameter.value.apply_method, "immediate") #lookup(parameter.value, "apply_method", "pending-reboot")
      name         = parameter.value.name
      value        = parameter.value.value
    }

  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "default" {
  engine                          = var.rds.engine
  instance_class                  = var.rds.instance_class
  identifier                      = var.create_prod_instance ? "${var.env_prefix}-${local.tags.project}-db-${random_string.db_name_suffix.result}" : "${var.env_prefix}-${local.tags.project}-db"
  engine_version                  = var.rds.engine_version
  password                        = random_password.master_password.result
  allocated_storage               = var.rds.allocated_storage
  max_allocated_storage           = var.rds.max_allocated_storage
  username                        = var.rds.username
  publicly_accessible             = var.rds.publicly_accessible
  parameter_group_name            = aws_db_parameter_group.default.name
  db_subnet_group_name            = aws_db_subnet_group.rds-mysql.id
  vpc_security_group_ids          = [aws_security_group.rds-mysql-sg.id]
  backup_retention_period         = var.rds.backup_retention_period
  skip_final_snapshot             = var.rds.skip_final_snapshot
  deletion_protection             = var.rds.deletion_protection
  depends_on                      = [aws_db_subnet_group.rds-mysql, aws_db_parameter_group.default, aws_security_group.rds-mysql-sg]
  enabled_cloudwatch_logs_exports = var.rds.enabled_cloudwatch_logs_exports
  storage_encrypted               = var.rds.storage_encrypted
  storage_type                    = var.rds.storage_type
  multi_az                        = var.rds.multi_az
  auto_minor_version_upgrade      = var.rds.enable_auto_minor_version_upgrade
  performance_insights_enabled    = var.rds.performance_insights_enabled
  monitoring_interval             = var.rds.monitoring_interval
  monitoring_role_arn             = aws_iam_role.enhanced_monitoring.arn
  blue_green_update {
    enabled = var.rds.blue_green_update
  }
  tags = local.tags
  lifecycle {
    ignore_changes = [engine_version]
  }
}


resource "aws_secretsmanager_secret" "rds-credentials" {
  name                    = var.create_prod_instance ? "${upper(local.tags.env_prefix)}-${local.tags.project}-rds-credentials-${random_string.db_name_suffix.result}" : "${upper(local.tags.env_prefix)}-${local.tags.project}-rds-credentials"
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds-credentials.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.default.username}",
  "password": "${random_password.master_password.result}",
  "engine": "${aws_db_instance.default.engine}",
  "host": "${split(":", aws_db_instance.default.endpoint)[0]}",
  "port": "${aws_db_instance.default.port}",
  "instance_identifier": "${aws_db_instance.default.identifier}"
}
EOF
  lifecycle {
    ignore_changes = [
    secret_string, ]
  }
}

# Create sns topic and subscriptions for RDS alerts
resource "aws_sns_topic" "rds_sns_topic" {
  name         = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-rds-sns-topic-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-rds-sns-topic"
  display_name = "devopx RDS Alerts"
  tags         = local.tags
}

resource "aws_sns_topic_subscription" "topic_sub" {
  for_each  = var.create_prod_instance ? toset(var.email_sns_endpoint) : []
  topic_arn = aws_sns_topic.rds_sns_topic.arn
  protocol  = "email"
  endpoint  = each.value
}


resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-db-connections-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-db-connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 500
  alarm_description   = "This metric monitors the number of database connections for the instance"
  alarm_actions       = [aws_sns_topic.rds_sns_topic.arn]
  ok_actions          = [aws_sns_topic.rds_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
  treat_missing_data = "notBreaching"
}


resource "aws_cloudwatch_metric_alarm" "db_freeable_memory" {
  alarm_name          = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-db-freeable-memory-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-db-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 200850534
  alarm_description   = "This metric monitors the amount of available random access memory for the database instance"
  alarm_actions       = [aws_sns_topic.rds_sns_topic.arn]
  ok_actions          = [aws_sns_topic.rds_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_utilization" {
  alarm_name          = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-db-cpu-utilization-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-db-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 95
  alarm_description   = "This metric monitors the percentage of CPU utilization for the database instance"
  alarm_actions       = [aws_sns_topic.rds_sns_topic.arn]
  ok_actions          = [aws_sns_topic.rds_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
  treat_missing_data = "breaching"

}

resource "aws_cloudwatch_metric_alarm" "db_freestoragespace" {
  alarm_name          = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-db-free-storage-space-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-db-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 10737418240
  alarm_description   = "This metric monitors the amount of available storage space for the database instance"
  alarm_actions       = [aws_sns_topic.rds_sns_topic.arn]
  ok_actions          = [aws_sns_topic.rds_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
  treat_missing_data = "notBreaching"
}

resource "aws_db_event_subscription" "default" {
  name        = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-db-event-subscription-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-db-event-subscription"
  sns_topic   = aws_sns_topic.rds_sns_topic.arn
  source_type = "db-instance"
  enabled     = true
  event_categories = [
    "availability",
    "deletion",
    "failover",
    "failure",
    "recovery",
    "restoration",
    "maintenance",
    "configuration change",
    "notification",
  ]
  tags = local.tags
}
