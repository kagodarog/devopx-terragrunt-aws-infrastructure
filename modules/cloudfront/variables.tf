variable "cf_domain_name" {
  type        = string
  description = "The domain name to use for the environment using beanstalk domain name"
}

variable "origin_id" {
  type        = string
  description = "The origin id for the cloudfront distribution"
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate to use for the cloudfront distribution"
}

variable "alias" {
  type        = string
  description = "The alias for the cloudfront distribution"
}

variable "env_prefix" {
  type        = string
  description = "The prefix for the environment"
}