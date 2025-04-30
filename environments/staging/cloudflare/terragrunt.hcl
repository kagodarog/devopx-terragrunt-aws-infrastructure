
# terragrunt.hcl

include {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/cloudflare"
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
  cf_pages_project_name = "v2-sync-demo-devopx"
  cf_pages_prod_branch  = "develop"
  account_id            = "eff14902be3be1888a16e62c99b34283"
  custom_domain         = "v2.sync-demo-staging.devopx.com"
  cloudflare_api_token  = lookup(dependency.data.outputs.aws_secretsmanager_secret_version, "CLOUDFLARE_API_TOKEN", "xxxxxxxXXXXXxxxxXXX")
}

# exclude {
#     if = true
#     actions = ["all"]
#     exclude_dependencies = true
# }