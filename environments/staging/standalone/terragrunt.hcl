
# terragrunt.hcl

include {
    path = find_in_parent_folders("root.hcl")
}


terraform {
    source = "../../../modules/standalone"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "vpc-12345678"
    public_subnet_ids  = ["subnet-12345678", "subnet-23456789"]
    private_subnet_ids = ["subnet-34567890", "subnet-45678901"]
  }
}


inputs = {
  #env_prefix           = local.tags.env_prefix
  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnets      = dependency.vpc.outputs.private_subnet_ids
  public_subnets       = dependency.vpc.outputs.public_subnet_ids
  instance_subnet_id   = dependency.vpc.outputs.public_subnet_ids[0]
}
