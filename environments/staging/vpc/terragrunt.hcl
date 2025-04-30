
# terragrunt.hcl

include {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/vpc"
}

inputs = {
  create_prod_instance = true
  cidr_block = "172.24.0.0/16"
  public_subnet_cidrs = [
  "172.24.0.0/20",
  "172.24.16.0/20",
  "172.24.32.0/20"
  ]
  private_subnet_cidrs = [
  "172.24.48.0/20",
  "172.24.64.0/20",
  "172.24.80.0/20"
  ]
}




