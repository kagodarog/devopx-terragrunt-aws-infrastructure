variable "private_subnets" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}
variable "env_prefix" {
  type        = string
  description = "value of the environment prefix"
  default     = "staging"
}

variable "create_rds_cluster" {
  type    = bool
  default = false
}

variable "create_prod_instance" {
  type    = bool
  default = false
}

variable "rds" {
  type = object({
    instance_class                    = string
    engine                            = string
    engine_version                    = string
    username                          = string
    allocated_storage                 = number
    max_allocated_storage             = optional(number)
    backup_retention_period           = number
    publicly_accessible               = bool
    multi_az                          = bool
    skip_final_snapshot               = bool
    storage_encrypted                 = bool
    storage_type                      = string
    deletion_protection               = bool
    enable_auto_minor_version_upgrade = bool
    blue_green_update                 = bool
    enabled_cloudwatch_logs_exports   = list(string)
    performance_insights_enabled      = bool
    monitoring_interval               = optional(number)
    db_custom_param = list(object({
      apply_method = string
      name         = string
      value        = string
    }))

  })
}

variable "email_sns_endpoint" {
  type        = list(string)
  default     = ["rogers@devopx.com"]
  description = "email address to receive notifications from RDS"
}
