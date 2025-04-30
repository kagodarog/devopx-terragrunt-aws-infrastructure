variable "account_id" {
  type = string
}
variable "cf_pages_prod_branch" {
  type = string
}
variable "cf_pages_project_name" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "custom_domain" {
  type = string
}

variable "env_prefix" {
  type    = string
  default = "staging"
}