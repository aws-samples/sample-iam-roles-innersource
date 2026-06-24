# Tests for a pod (IRSA) role: no instance profile and no default managed policies.

mock_provider "aws" {}

variables {
  tags = { env = "test" }
}

run "pod_role_without_instance_profile" {
  command = plan

  variables {
    role_name = "test-pod-role"
    identity_policy = [
      {
        policy    = "s3/readonly"
        resources = ["arn:aws:s3:::test-bucket"]
      }
    ]
    trust_policy = {
      policy = "pod"
      parameters = [
        {
          cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/TESTID"
          cluster_oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/TESTID"
          pod_namespace             = "test-ns"
          app                       = "test-app"
        }
      ]
    }
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 0
    error_message = "Non-ec2 trust policy must not create an instance profile"
  }

  assert {
    condition     = length(output.managed_policy_arns) == 0
    error_message = "pod trust policy has no default managed policies"
  }
}
