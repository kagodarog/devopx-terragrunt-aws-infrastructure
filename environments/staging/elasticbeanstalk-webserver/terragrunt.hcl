
# terragrunt.hcl

include {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/elasticbeanstalk"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "vpc-12345678"
    public_subnet_ids  = ["subnet-12345678", "subnet-23456789"]
    private_subnet_ids = ["subnet-34567890", "subnet-45678901"]
    elasticloadbalancer_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188"
  }
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    aws_secretsmanager_secret_version = {
      DEFAULT_URL           = "https://example.com"
      ADMIN_EMAIL           = ""
    }
  }
}


inputs = {
  vpc_id                                     = dependency.vpc.outputs.vpc_id
  private_subnet_ids                         = dependency.vpc.outputs.private_subnet_ids
  public_subnet_ids                          = dependency.vpc.outputs.public_subnet_ids
  shared_loadbalancer_arn                    = dependency.vpc.outputs.elasticloadbalancer_arn
  elasticbeanstalk_tier                      = "WebServer"
  elasticbeanstalk_app_name                  = "devopx"
  ec2_instance_profile                       = ""
  eb_service_role_name                       = ""
  enabled                                    = true
  create_eb_app_version                      = true
  enable_spot_instances                      = true
  spot_fleet_on_demand_above_base_percentage = 0
  solution_stack_name                        = "64bit Amazon Linux 2023 v4.6.1 running PHP 8.2"
  root_volume_size                           = 8
  instance_types                             = ["t4g.nano", "t4g.micro"]
  autoscale_min                              = 1
  port443rulename                            = "443rules"
  shared_lb_listener_priority                = 1
  #env_vars_secret_id                         = local.aws_secret_manager_name
  notification_email                         = "kagodarog@gmail.com"
  eventbridge_filtered_eb_alert_email        = ["kagodarog@gmail.com"]
  extended_ec2_policy_document               = ""
  domain_name                                = "sync-demo-staging.devopx.com"
  rolling_update_enabled                     = false
  deployment_policy                          = "AllAtOnce"
  updating_max_batch                         = 2
  update_level                               = "patch"
  instance_refresh_enabled                   = false
  preferred_start_time                       = "Tue:03:00"
  php_settings = {
    document_root      = "/web"
    display_errors     = "Off"
    max_execution_time = "300"
    memory_limit       = "512M"
  }

  env_vars = {
    DEFAULT_URL           = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "DEFAULT_URL", "https://example.com")
    ADMIN_EMAIL           = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "ADMIN_EMAIL", "")
    SUPPORT_EMAIL         = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SUPPORT_EMAIL", "")
    SALT                  = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SALT", "")
    CAPTCHA_KEY           = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "CAPTCHA_KEY", "")
    CAPTCHA_SECRET        = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "CAPTCHA_SECRET", "")
    ENCRYPTION_IV         = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "ENCRYPTION_IV", "")
    ENCRYPTION_KEY        = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "ENCRYPTION_KEY", "")
    MYSQL_HOST            = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "MYSQL_HOST", "")
    MYSQL_PORT            = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "MYSQL_PORT", "")
    MYSQL_DATABASE        = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "MYSQL_DATABASE", "")
    MYSQL_USER            = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "MYSQL_USER", "")
    MYSQL_PASSWORD        = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "MYSQL_PASSWORD", "")
    SMTP_HOST             = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SMTP_HOST", "")
    SMTP_PORT             = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SMTP_PORT", "")
    SMTP_USER             = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SMTP_USER", "")
    SMTP_PASSWORD         = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SMTP_PASSWORD", "")
    SMTP_ENCRYPTION       = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "SMTP_ENCRYPTION", "")
    COOKIE_VALIDATION_KEY = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "COOKIE_VALIDATION_KEY", "")
    LOOGLY_ID             = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "LOOGLY_ID", "")
    ENV_TYPE              = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "ENV_TYPE", "")
  }
}




