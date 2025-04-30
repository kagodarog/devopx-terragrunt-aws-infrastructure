
variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
}
variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "devopx"
}

variable "env_prefix" {
  description = "The prefix for the environment"
  type        = string
  default     = "staging"
}

variable "domainname" {
  description = "The domain name for the application"
  type        = string
  default     = "devopx.com"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "staging"
}