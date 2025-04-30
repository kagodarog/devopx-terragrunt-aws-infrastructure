<<<<<<< HEAD
# devopx-terragrunt-aws-infrastructure
=======
# devopx Infra

This repository contains the infrastructure code for the devopx project. The infrastructure is managed using [Terraform](https://www.terraform.io/) and is designed to be deployed on [AWS](https://aws.amazon.com/).


## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)

## Prerequisites

Before you begin, ensure you have met the following requirements:
- You have installed [Terraform](https://www.terraform.io/downloads.html). Versions 1.5.0 or later.
- You have an AWS account and the necessary permissions to create resources.
- You have configured your [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html).
- You also need the Cloudflare API token for managing the [Cloudflare Pages](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/). The scoped permissions of workers and pages are required.
## Installation

1. Clone the repository:
    ```sh
    git clone https://bitbucket.org/j-alexis/devopx-infra/src/main/git
    ```
2. Navigate to the project directory:
    ```sh
    cd devopx-infra
    ```

## Structure

The infrastructure is divided into two environments: `staging` and `prod`. Each environment has its own Terraform configuration and state file. The `global` directory contains shared modules that are used across environments. The `modules` directory contains reusable modules that can be used in the environment configurations.

```
├── README.md
├── global
│   ├── aws_route53
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── iam
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── ses_smtp_user
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── vpc-elb
│       ├── Makefile
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       ├── variables.tf
│       └── versions.tf
├── modules
│   ├── cloudflare
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── cloudwatch
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── elasticbeanstalk
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── security.tf
│   │   └── variables.tf
│   └── rds
│       ├── main.tf
│       ├── outputs.tf
│       ├── security.tf
│       └── variables.tf
├── prod
│   ├── Makefile
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── versions.tf
└── staging
    ├── Makefile
    ├── main.tf
    ├── outputs.tf
    ├── snapshot.tf
    ├── terraform.tfvars
    ├── variables.tf
    └── versions.tf
```

## Files and Directories

**Global**

Important: You need to create the following resources in the global directory before creating any other environment.

- **global/aws_route53:** This module creates a Route 53 hosted zone and a set of DNS records for the domain.

- **global/iam:** This module creates IAM roles and policies for the Elastic Beanstalk environment.

- **global/ses_smtp_user:** This module creates an SES SMTP user for sending emails.

- **global/vpc-elb:** This module creates a VPC with public and private subnets, an internet gateway, and a NAT gateway. It also creates an Elastic Load Balancer (ELB) with an SSL certificate.

**Modules**

- **cloudflare:** This module creates a Cloudflare DNS record for the domain.
- **cloudwatch:** This module creates CloudWatch alarms for monitoring the environment.
- **elasticbeanstalk:** This module creates an Elastic Beanstalk environment with an RDS database.
- **rds:** This module creates an RDS database.
- **s3:** This module creates an S3 bucket.
- **vpc:** This module creates a VPC with public and private subnets.

Where each environment has the following files:

- **main.tf:** The main Terraform configuration file.
- **outputs.tf:** The output variables.
- **terraform.tfvars:** The Terraform variables.
- **variables.tf:** The input variables.
- **versions.tf:** The Terraform version constraints.


**Prod**  
    This directory contains the Terraform configuration for the production environment.  
- **Makefile:** The Makefile for managing the Terraform commands.  
- **main.tf:** The main Terraform configuration file.  
- **outputs.tf:** The output variables.  
- **terraform.tfvars:** The Terraform variables.  
- **variables.tf:** The input variables.  
- **versions.tf:** The Terraform version constraints.  


**Staging**  
    This directory contains the Terraform configuration for the staging environment.  
- **Makefile:** The Makefile for managing the Terraform commands.  
- **main.tf:** The main Terraform configuration file.  
- **outputs.tf:** The output variables.  
- **terraform.tfvars:** The Terraform variables.  
- **variables.tf:** The input variables.  
- **versions.tf:** The Terraform version constraints.  

## Usage

1. Move to the global directory and then first setup the VPC resources found in the vpc-elb folder followed by the other folders within the global directory.
<br>Then, Initialize Terraform:
    ```sh
    terraform init
    ```
2. Plan the infrastructure changes:
    ```sh
    terraform plan
    ```
3. Apply the infrastructure changes:
    ```sh
    terraform apply
    ```
>>>>>>> 7f6e48d (chore: update readme)
