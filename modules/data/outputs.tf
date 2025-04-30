output "aws_secretsmanager_secret_version" {
  value = jsondecode(data.aws_secretsmanager_secret_version.env_vars.secret_string)
  sensitive = true
}