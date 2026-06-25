# Example: IAM role for an EC2 instance.
#
# Using trust_policy.policy = "ec2" automatically:
#   - attaches the AmazonSSMManagedInstanceCore managed policy, and
#   - creates an instance profile.
#
# Run from this directory:
#   terraform init
#   terraform plan

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "iam_role" {
  source = "../../"

  role_name = "example-ec2-role"

  identity_policy = [
    {
      policy    = "s3/readonly"
      resources = ["arn:aws:s3:::amzn-s3-demo"]
    },
    {
      policy    = "dynamodb/readonly"
      resources = ["arn:aws:dynamodb:us-east-1:123456789012:table/example-table"]
    }
  ]

  trust_policy = {
    policy = "ec2"
  }

  tags = {
    env  = "dev"
    app  = "example"
    team = "platform"
  }
}

output "role_arn" {
  description = "ARN of the created IAM role"
  value       = module.iam_role.role_arn
}

output "instance_profile_arn" {
  description = "ARN of the created instance profile"
  value       = module.iam_role.instance_profile_arn
}

output "managed_policy_arns" {
  description = "Managed policies applied automatically"
  value       = module.iam_role.managed_policy_arns
}
