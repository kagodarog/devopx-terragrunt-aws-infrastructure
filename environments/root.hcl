
# Root terragrunt.hcl file

locals {
  
  # Load region variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  # Load env variables
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract commonly used variables
  aws_region          = local.region_vars.locals.aws_region
  env_vars            = local.environment_vars.locals
  environment         = local.environment_vars.locals.tags.env_prefix
  tags                = local.environment_vars.locals.tags
  aws_secret_manager_name     = local.environment_vars.locals.aws_secret_name
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy  = "Terragrunt"
    }
  }
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${dirname(path_relative_to_include())}-devopx-terraform-state-${local.aws_region}"
    key            = "terragrunt/${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    use_lockfile = true

  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure root level variables that all resources can inherit
# inputs = merge(
#   local.region_vars.locals,
#   local.environment_vars.locals,
#   #env_prefix = local.environment_vars.locals.tags.env_prefix
# )

inputs = {
  env_prefix = local.environment_vars.locals.tags.env_prefix
  region     = local.aws_region
  tags       = local.tags
  env_vars_secret_id = local.aws_secret_manager_name
  # Add any other common variables here
}