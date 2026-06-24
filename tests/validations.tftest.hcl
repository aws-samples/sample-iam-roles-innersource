# Tests for input validation: the module must reject unsafe or malformed input.

mock_provider "aws" {}

variables {
  tags = { env = "test" }
  trust_policy = {
    policy = "ec2"
  }
}

run "reject_wildcard_resource" {
  command = plan

  variables {
    role_name = "test-role"
    identity_policy = [
      {
        policy    = "s3/readonly"
        resources = ["arn:aws:s3:::*"]
      }
    ]
  }

  expect_failures = [var.identity_policy]
}

run "reject_invalid_policy_format" {
  command = plan

  variables {
    role_name = "test-role"
    identity_policy = [
      {
        policy    = "s3-readonly"
        resources = ["arn:aws:s3:::test-bucket"]
      }
    ]
  }

  expect_failures = [var.identity_policy]
}

run "reject_too_long_role_name" {
  command = plan

  variables {
    role_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    identity_policy = [
      {
        policy    = "s3/readonly"
        resources = ["arn:aws:s3:::test-bucket"]
      }
    ]
  }

  expect_failures = [var.role_name]
}
