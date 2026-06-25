# Example: IAM role for a Kubernetes/OpenShift pod (IRSA).
#
# The pod trust policy renders one statement per entry in `parameters`,
# so the same role can be assumed from multiple clusters.
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

  role_name = "example-pod-role"

  identity_policy = [
    {
      policy    = "s3/readonly"
      resources = ["arn:aws:s3:::amzn-s3-demo"]
    }
  ]

  trust_policy = {
    policy = "pod"
    parameters = [
      {
        cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
        cluster_oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
        pod_namespace             = "example-namespace"
        app                       = "example"
      }
    ]
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
