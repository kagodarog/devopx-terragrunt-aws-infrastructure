provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_pages_project" "devopx_react" {
  account_id        = var.account_id
  name              = "${var.cf_pages_project_name}-${var.env_prefix}"
  production_branch = var.cf_pages_prod_branch

  deployment_configs = {
    production = {
      compatibility_date  = "2022-08-16"
      compatibility_flags = ["nodejs_compat"]
    }

    preview = {
      compatibility_date  = "2022-08-16"
      compatibility_flags = ["nodejs_compat"]
    }
  }
  lifecycle {
    ignore_changes = [build_config]
  }
}

resource "cloudflare_pages_domain" "pages_project" {
  account_id   = var.account_id
  project_name = cloudflare_pages_project.devopx_react.name
  name       = var.custom_domain
}

resource "cloudflare_pages_domain" "pages_project_www" {
  account_id   = var.account_id
  project_name = cloudflare_pages_project.devopx_react.name
  name       = "www.${var.custom_domain}"
}