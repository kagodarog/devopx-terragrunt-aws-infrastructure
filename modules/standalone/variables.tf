
variable "eip_allocation_id" {
  description = "The Elastic IP allocation ID"
  default     = "eipalloc-06a2a268497f3efa2"
}
variable "env_vars_secret_id" {
  description = "The AWS secret manager name or id for the environment variables"
  default     = "/staging/devopx/eb_secrets"
}
variable "cloudflare_api_token" {}

variable "instance_subnet_id" {
  description = "The Public subnet ID for the EC2 instance"
  type        = string
}

variable "env_prefix" {
  description = "The prefix for the environment"
  type        = string
  default     = "staging"
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}