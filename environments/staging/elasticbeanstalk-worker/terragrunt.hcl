
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


dependency "elasticbeanstalk-webserver" {
  config_path = "../elasticbeanstalk-webserver"
  mock_outputs = {
    elasticbeanstalk_app_name            = "my-app"
    elasticbeanstalk_instance_profile    = "aws-elasticbeanstalk-ec2-role"
    elasticbeanstalk_service_role        = "aws-elasticbeanstalk-service-role"
    elasticbeanstalk_environment_name    = "my-env"
    elasticbeanstalk_environment_url     = "http://my-env.us-west-2.elasticbeanstalk.com"
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
  elasticbeanstalk_tier                      = "Worker"
  elasticbeanstalk_app_name                  = dependency.elasticbeanstalk-webserver.outputs.elasticbeanstalk_app_name
  ec2_instance_profile                       = dependency.elasticbeanstalk-webserver.outputs.elasticbeanstalk_instance_profile
  eb_service_role_name                       = dependency.elasticbeanstalk-webserver.outputs.elasticbeanstalk_service_role
  enabled                                    = false
  create_eb_app_version                      = false
  enable_spot_instances                      = true
  spot_fleet_on_demand_above_base_percentage = 0
  solution_stack_name                        = "64bit Amazon Linux 2023 v4.1.3 running PHP 8.2"
  root_volume_size                           = 8
  instance_types                             = ["m6g.large", "t4g.large", "m7g.large"]
  autoscale_min                              = 1
  port443rulename                            = ""
  #env_vars_secret_id                         = local.aws_secret_manager_name
  notification_email                         = "kagodarog@gmail.com"
  extended_ec2_policy_document               = ""
  domain_name                                = "sync-demo-staging.devopx.com"
  rolling_update_enabled                     = false
  deployment_policy                          = "AllAtOnce"
  shared_loadbalancer_arn                    = dependency.vpc.outputs.elasticloadbalancer_arn
  updating_max_batch                         = 2
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




