data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_secretsmanager_secret_version" "env_vars" {
  secret_id = var.aws_secret_manager_name
}