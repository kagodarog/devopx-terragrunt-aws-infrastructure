resource "aws_security_group" "rds-mysql-sg" {
  name        = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}rds-pg-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}rds-pg"
  vpc_id      = var.vpc_id
  description = "Ingress to staging MySQL DB"

  tags = merge(
    local.tags,
    {
      "Name"      = var.create_prod_instance ? "${local.tags.env_prefix}-mysql-sg-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-mysql-sg"
      Environment = local.tags.env_prefix
      Project     = local.tags.project
    }
  )
}

resource "aws_security_group_rule" "rds-sg" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.rds-mysql-sg.id
}

resource "aws_security_group_rule" "rds-sg2" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["172.31.0.0/16"]
  security_group_id = aws_security_group.rds-mysql-sg.id
}

resource "aws_security_group_rule" "rds-sg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds-mysql-sg.id
}

resource "aws_iam_role" "enhanced_monitoring" {
  name = var.create_prod_instance ? "${local.tags.env_prefix}-${local.tags.project}-rds-enhanced-monitoring-${random_string.db_name_suffix.result}" : "${local.tags.env_prefix}-${local.tags.project}-rds-enhanced-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}