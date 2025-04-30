locals {
  tags = {
    env_prefix = "staging"
    company    = "devopx"
  }
  aws_secret_name = "/staging/devopx/eb_secrets"
  ingress_rules = {
    port22 = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    port3306 = {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16", "102.36.218.235/32", "172.31.5.92/32"]
    }
  }
  }