variable "aws_secret_manager_name" {
  description = "The AWS secret manager name or id for the environment variables"
  type        = string
  default     = "/staging/devopx/eb_secrets"
}