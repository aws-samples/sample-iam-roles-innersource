# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Module support for the `{{RESOURCE_ARN}}/index/*` placeholder so DynamoDB templates can scope to a table's secondary indexes.

### Changed

- Tightened the DynamoDB templates to explicit item-level actions and scoped them to the table and its indexes. Removed table-management actions (`CreateTable`, and the `Delete*`/`Update*` wildcards that allowed `DeleteTable`/`UpdateContinuousBackups`) and the broad `*` list/describe statement, aligning with AWS least-privilege guidance.
- Renamed the SQS templates `readonly` -> `consumer` and `writeonly` -> `producer` to reflect messaging roles accurately (the old `readonly` mislabeled a message-deleting consumer). **Breaking:** update any `policy = "sqs/readonly"` or `"sqs/writeonly"` references to `sqs/consumer` / `sqs/producer`.
- KMS `default` now lists `kms:ReEncryptFrom` and `kms:ReEncryptTo` explicitly instead of the `kms:ReEncrypt*` wildcard, so no template uses action wildcards.

## [1.0.0] - 2026-06-23

Initial public release.

### Added

- IAM role creation with template-based inline policies and trust policies.
- Identity policy templates for Bedrock, DynamoDB, EventBridge, KMS, Lambda, S3
  (including cross-region replication), Secrets Manager, SNS, SQS, SSM Parameter
  Store, and Step Functions, organized by access type (`default`, `readonly`,
  `writeonly`).
- Trust policy templates for EC2, EventBridge, Lambda, pods (IRSA), S3, and Step
  Functions, plus custom trust policy support (`ec2-lambda`, `eventbridge-lambda`).
- Automatic managed policy attachment based on the trust policy type.
- Automatic EC2 instance profile creation.
- Configurable role path (`role_path`).
- Input validation: `service/policy` format and full-ARN resources with no
  wildcards.
- Runnable examples (`examples/ec2`, `examples/pod`).
- Native Terraform tests using `mock_provider` (no AWS credentials required).
- CI workflow running fmt, validate, example validation, tests, tflint, and checkov.
- Contributor documentation: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`,
  `CODEOWNERS`, issue templates, and a pull request template.
- Apache 2.0 license.
