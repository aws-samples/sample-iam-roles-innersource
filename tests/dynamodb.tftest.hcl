# Tests for the DynamoDB templates: explicit item-level actions, secondary-index
# scoping, and no table-management actions.

mock_provider "aws" {}

variables {
  tags = { env = "test" }
  trust_policy = {
    policy = "lambda"
  }
}

run "dynamodb_default_is_least_privilege" {
  command = plan

  variables {
    role_name = "test-ddb-role"
    identity_policy = [
      {
        policy    = "dynamodb/default"
        resources = ["arn:aws:dynamodb:us-east-1:123456789012:table/example"]
      }
    ]
  }

  assert {
    condition     = anytrue([for p in values(aws_iam_role_policy.inline) : strcontains(p.policy, "arn:aws:dynamodb:us-east-1:123456789012:table/example/index/*")])
    error_message = "DynamoDB policy must scope to the table's secondary indexes (.../index/*)"
  }

  assert {
    condition     = alltrue([for p in values(aws_iam_role_policy.inline) : !strcontains(p.policy, "{{")])
    error_message = "Rendered policy must not contain unresolved placeholders"
  }

  assert {
    condition     = alltrue([for p in values(aws_iam_role_policy.inline) : !strcontains(p.policy, "dynamodb:CreateTable") && !strcontains(p.policy, "dynamodb:DeleteTable")])
    error_message = "DynamoDB templates must not grant table-management actions"
  }
}
