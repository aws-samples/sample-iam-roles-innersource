# Tests for an EC2 role: instance profile creation and default managed policy.
# Uses mock_provider so no AWS credentials are required.

mock_provider "aws" {}

variables {
  tags = { env = "test" }
}

run "ec2_role_with_instance_profile" {
  command = plan

  variables {
    role_name = "test-ec2-role"
    identity_policy = [
      {
        policy    = "s3/readonly"
        resources = ["arn:aws:s3:::test-bucket"]
      }
    ]
    trust_policy = {
      policy = "ec2"
    }
  }

  assert {
    condition     = aws_iam_role.this.name == "test-ec2-role"
    error_message = "Role name did not match the requested name"
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 1
    error_message = "EC2 trust policy must create exactly one instance profile"
  }

  assert {
    condition     = contains(output.managed_policy_arns, "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore")
    error_message = "EC2 role must receive the AmazonSSMManagedInstanceCore managed policy"
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 1
    error_message = "Expected exactly one inline policy"
  }
}
