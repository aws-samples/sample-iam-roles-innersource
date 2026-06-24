# IAM Role Terraform Module

> Open-source Terraform module | InnerSource governance | Least privilege by default

> [!IMPORTANT]
> **Disclaimer — illustrative examples, not production-ready.** This repository is a
> demonstration of the InnerSource pattern for managing IAM roles. The policy
> templates here are simplified, illustrative examples and **must not be used in
> production as-is**. Review and test every policy before use, and create the
> policies that actually fit your own workloads, following the principle of least
> privilege. You are responsible for the IAM permissions you deploy.

A shared Terraform module for creating AWS IAM Roles with curated, template-based
inline policies and flexible trust policies. It is designed to be adopted across an
organization using an **InnerSource** model: a central team owns the security
guardrails, and any application team can consume the module and contribute new
policy templates through pull requests.

This repository is a reference implementation. It is provided as-is under the
[Apache 2.0 License](LICENSE) so that any organization can fork it and adapt it to
its own standards.

## Table of Contents

- [IAM Role Terraform Module](#iam-role-terraform-module)
  - [Table of Contents](#table-of-contents)
  - [Why InnerSource for IAM Roles](#why-innersource-for-iam-roles)
  - [Governance Model](#governance-model)
  - [Key Features](#key-features)
  - [How It Works](#how-it-works)
    - [Default Managed Policies](#default-managed-policies)
    - [Customizing Managed Policies](#customizing-managed-policies)
  - [Quick Start](#quick-start)
    - [Prerequisites](#prerequisites)
    - [Basic Usage](#basic-usage)
  - [Directory Structure](#directory-structure)
  - [Usage](#usage)
    - [Basic Example (EC2)](#basic-example-ec2)
    - [Parameterized Example (Pod/EKS) - Single Cluster](#parameterized-example-podeks---single-cluster)
    - [S3 Cross-Region Replication Example](#s3-cross-region-replication-example)
    - [Custom Trust Policy Example](#custom-trust-policy-example)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Template Structure](#template-structure)
    - [Identity Policy Templates](#identity-policy-templates)
    - [Trust Policy Templates](#trust-policy-templates)
  - [Available Templates](#available-templates)
    - [Identity Policy Templates](#identity-policy-templates-1)
    - [Trust Policy Templates](#trust-policy-templates-1)
  - [Adding New Templates](#adding-new-templates)
    - [Add an Identity Policy Template](#add-an-identity-policy-template)
    - [Add a Trust Policy Template](#add-a-trust-policy-template)
  - [Validation and Security](#validation-and-security)
    - [ARN Validation](#arn-validation)
    - [Policy Format Validation](#policy-format-validation)
    - [Best Practices](#best-practices)
  - [Testing](#testing)
    - [Continuous integration](#continuous-integration)
  - [Troubleshooting](#troubleshooting)
      - [Error: "The policy field must follow the 'service/policy' format"](#error-the-policy-field-must-follow-the-servicepolicy-format)
      - [Error: "Wildcards (\*) are not allowed"](#error-wildcards--are-not-allowed)
      - [Error: "Template file not found"](#error-template-file-not-found)
      - [Error: "Error assuming role"](#error-error-assuming-role)
    - [Debugging](#debugging)
  - [Contributing](#contributing)
  - [Security](#security)
  - [License](#license)
  - [References](#references)

## Why InnerSource for IAM Roles

IAM is high-stakes and easy to get wrong. Two common failure modes appear as
organizations scale on AWS:

- **Central bottleneck:** a single security team authors every role, and delivery
  slows down while teams wait in a queue.
- **Uncontrolled sprawl:** every team writes its own roles, and over-permissive
  policies and wildcards proliferate with no consistent review.

InnerSource resolves this tension by applying open-source practices inside the
organization. A central team publishes a shared module that encodes the guardrails
(least-privilege templates, ARN validation, consistent tagging), and application
teams consume it through a versioned interface. When a team needs a capability the
module does not yet support, they contribute a template through a pull request that
the maintainers review. The guardrails stay central; the contribution is
distributed.

This module is a concrete implementation of that pattern.

## Governance Model

This module follows a **centralized governance with distributed contribution**
model:

```
+-------------------------------------------------------------+
|                  Maintainers (central team)                 |
|  e.g. a Platform Engineering or Cloud Security team         |
|  - Own and version the module                               |
|  - Review and approve every change                          |
|  - Keep templates aligned with least privilege              |
+-------------------------------------------------------------+
                            ^
                            | Pull Requests (review required)
                            |
+-------------------------------------------------------------+
|                Application / Workload teams                 |
|  - Consume the module via a pinned version                  |
|  - Contribute new policy templates                          |
|  - Report issues and request features                       |
+-------------------------------------------------------------+
```

The maintainers act as [trusted committers](https://patterns.innersourcecommons.org/p/trusted-committer):
they are responsible for the security posture of the module and have the final say
on merges. Any team can open a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the full workflow and review criteria.

In InnerSource terms, this is a **project-specific** model: a dedicated team owns a
single shared asset while contribution stays open to everyone. It contrasts with the
infrastructure-based model, where a platform team provides only the hosting and
tooling and any team spins up its own projects. Organizations often start
infrastructure-based and graduate high-value assets like this one to a
project-specific model.

The module's **modular, template-per-service layout** is what makes distributed
contribution safe: each template is an isolated file, so multiple teams can add or
change templates in parallel with minimal merge conflicts, and a reviewer can reason
about one template at a time.

## Key Features

- Creates an IAM Role with a customizable name and path.
- Supports multiple inline policies per role.
- Uses policy templates organized by service and access type.
- Supports trust policies with dynamic parameters (e.g. for EKS and ROSA).
- Supports custom trust policies (`trust_policy_templates/custom/`).
- Creates an instance profile automatically for EC2.
- Applies required tags to all resources.
- Validates resource ARNs (wildcards `*` are not allowed).
- Applies managed policies automatically based on the trust policy type (e.g.
  `AmazonSSMManagedInstanceCore` for EC2).

## How It Works

1. The module identifies the trust policy type in use (e.g. `ec2`, `lambda`, `pod`).
2. It reads `identity_policy_templates/default_managed_policies.json`.
3. It automatically applies the managed policies configured for that type.
4. Managed policies are attached to the role via `aws_iam_role_policy_attachment`.

### Default Managed Policies

> Generated from `default_managed_policies.json` by `scripts/generate_template_docs.py` — run `make docs` after editing it.

<!-- BEGIN_MANAGED_POLICIES -->
| Trust Policy | Managed Policies Applied |
|--------------|--------------------------|
| `ec2` | `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` |
| `lambda` | `arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole` |
<!-- END_MANAGED_POLICIES -->

**Note on the instance profile:** The module automatically creates an instance
profile when the trust policy name **contains "ec2"**. This means trust policies
such as `ec2`, `custom/ec2-lambda`, or `ec2-something` all result in an instance
profile being created.

**Note on custom trust policies:** Custom trust policies (in the `custom/` folder)
are also supported. The module extracts the prefix from the template name to decide
which set of managed policies to apply.

**Prefix extraction examples:**

- `ec2` -> applies `ec2` managed policies
- `lambda` -> applies `lambda` managed policies
- `custom/ec2-lambda` -> extracts `ec2-lambda` and applies that type's managed policies (if configured)
- `custom/eventbridge-lambda` -> extracts `eventbridge-lambda` and applies that type's managed policies (if configured)

### Customizing Managed Policies

You can add or change the automatic managed policies by editing
`identity_policy_templates/default_managed_policies.json`.

**File structure:**

```json
{
  "trust-policy-type": [
    "arn:aws:iam::aws:policy/ManagedPolicyName1",
    "arn:aws:iam::aws:policy/ManagedPolicyName2"
  ]
}
```

To disable automatic managed policies for a given type, remove the entry or set an
empty array. Removing default managed policies may break the service: for example,
Lambda functions without `AWSLambdaBasicExecutionRole` cannot write logs to
CloudWatch, and EC2 instances without `AmazonSSMManagedInstanceCore` cannot be
managed through Systems Manager.

## Quick Start

### Prerequisites

- Terraform >= 1.3 (the module uses `optional()` object attribute defaults)
- AWS Provider >= 5.0, configured
- Permissions to create IAM Roles

### Basic Usage

```hcl
module "iam_role" {
  source = "./path/to/this/module"

  role_name = "my-application-role"

  identity_policy = [
    {
      policy    = "s3/readonly"
      resources = ["arn:aws:s3:::amzn-s3-demo"]
    }
  ]

  trust_policy = {
    policy = "ec2"
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

Runnable examples live in the [`examples/`](examples/) folder:

- [`examples/ec2`](examples/ec2) - role for EC2 instances
- [`examples/pod`](examples/pod) - role for Kubernetes/OpenShift pods (IRSA)

## Directory Structure

```
.
├── identity_policy_templates/    # Identity (inline) policy templates
│   ├── <service>/                #   e.g. s3, dynamodb, kms, sqs, ssm, ...
│   │   ├── default.tftpl         #   read + write
│   │   ├── readonly.tftpl        #   read only (optional)
│   │   └── writeonly.tftpl       #   write only (optional)
│   └── default_managed_policies.json
├── trust_policy_templates/       # Trust policy templates
│   ├── <service>.tftpl           #   e.g. ec2, lambda, pod, s3, ...
│   └── custom/                   # Custom trust policies
│       └── <name>.tftpl
├── examples/
│   ├── ec2/
│   │   └── main.tf
│   └── pod/
│       └── main.tf
├── tests/
│   ├── ec2.tftest.hcl
│   ├── pod.tftest.hcl
│   └── validations.tftest.hcl
├── scripts/
│   └── generate_template_docs.py # Regenerates the README template catalog
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── Makefile
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Usage

### Basic Example (EC2)

```hcl
module "iam_role" {
  source = "./path/to/this/module"

  role_name = "my-iam-role"

  identity_policy = [
    {
      policy    = "s3/default"
      resources = ["arn:aws:s3:::amzn-s3-demo"]
    },
    {
      policy    = "dynamodb/readonly"
      resources = ["arn:aws:dynamodb:us-east-1:123456789012:table/my-table"]
    }
  ]

  trust_policy = {
    policy = "ec2"
  }

  tags = {
    env = "prod"
    app = "my-app"
  }
}
```

**Note:** This example automatically applies the `AmazonSSMManagedInstanceCore`
managed policy because it uses `trust_policy.policy = "ec2"`. It also creates an
instance profile.

### Parameterized Example (Pod/EKS) - Single Cluster

```hcl
module "iam_role" {
  source = "./path/to/this/module"

  role_name = "my-pod-role"

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
        pod_namespace             = "my-namespace"
        app                       = "my-app"
      }
    ]
  }

  tags = {
    env = "prod"
  }
}
```

The `parameters` list generates one statement per item, which is useful when
multiple EKS/OpenShift clusters assume the same role.

### S3 Cross-Region Replication Example

The `s3/replication` template needs a `source_bucket` parameter (the source bucket
ARN) in addition to `resources` (the destination bucket ARN). The `parameters` map
on an identity policy entry fills template placeholders such as `{{source_bucket}}`.

```hcl
module "iam_role" {
  source = "./path/to/this/module"

  role_name = "my-replication-role"

  identity_policy = [
    {
      policy    = "s3/replication"
      resources = ["arn:aws:s3:::amzn-s3-demo-destination-bucket'"]
      parameters = {
        source_bucket = "arn:aws:s3:::my-source-bucket"
      }
    }
  ]

  trust_policy = {
    policy = "s3"
  }

  tags = {
    env = "prod"
  }
}
```

### Custom Trust Policy Example

```hcl
module "iam_role" {
  source = "./path/to/this/module"

  role_name = "my-custom-role"

  identity_policy = [
    {
      policy    = "s3/default"
      resources = ["arn:aws:s3:::amzn-s3-demo"]
    }
  ]

  trust_policy = {
    policy = "custom/ec2-lambda" # Uses trust_policy_templates/custom/ec2-lambda.tftpl
  }

  tags = {
    env = "dev"
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `role_name` | `string` | yes | n/a | Name of the IAM Role to create (1-64 chars; `[\w+=,.@-]`). |
| `identity_policy` | `list(object)` | yes | n/a | List of inline policies. See structure below. |
| `trust_policy` | `object` | yes | n/a | Trust policy to use. See structure below. |
| `tags` | `map(string)` | yes | n/a | Tags applied to all created resources. |
| `role_path` | `string` | no | `"/"` | IAM role path. Must begin and end with `/` (e.g. `/platform/`). |

**`identity_policy` item structure:**

- `policy` (string): `service/policy` format (e.g. `s3/default`, `dynamodb/readonly`).
- `resources` (list(string)): resource ARNs. Wildcards (`*`) are not allowed.
- `parameters` (map(string), optional): values for template placeholders such as `{{source_bucket}}`. Defaults to `{}`.

**`trust_policy` structure:**

- `policy` (string): template name (e.g. `ec2`, `lambda`, `pod`, `custom/ec2-lambda`).
- `parameters` (list(map(string)), optional): one statement is generated per list item. Useful for multi-cluster EKS/OpenShift scenarios.

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `role_arn` | `string` | ARN of the created IAM role. |
| `role_name` | `string` | Name of the created IAM role. |
| `instance_profile_arn` | `string` | ARN of the instance profile (created when the trust policy name contains "ec2"; otherwise `null`). |
| `managed_policy_arns` | `list(string)` | ARNs of the managed policies applied automatically based on the trust policy. |

## Template Structure

### Identity Policy Templates

Identity policy templates use the following format:

```json
{
  "policies": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:PutObject"],
        "Resource": ["{{RESOURCE_ARN}}"]
      }
    ]
  },
  "managed_policies": []
}
```

**Supported placeholders:**

- `{{RESOURCE_ARN}}`: replaced by the ARNs provided in `resources`.
- `{{RESOURCE_ARN}}/*`: appends `/*` to each ARN (useful for S3 objects).
- `{{<parameter>}}`: replaced by the matching value from the identity policy `parameters` map.
- `{{<parameter>}}/*`: replaced by the matching parameter value with `/*` appended.

### Trust Policy Templates

Trust policy templates can be simple (no parameters), parameterized, or custom.

**Simple template** (`trust_policy_templates/{policy}.tftpl`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Parameterized template** (renders one statement per `parameters` entry):

```json
{
  "Version": "2012-10-17",
  "Statement": [
%{ for idx, param in parameters ~}
    {
      "Effect": "Allow",
      "Principal": { "Federated": "${param.cluster_oidc_provider_arn}" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${param.cluster_oidc_provider_url}:aud": "sts.amazonaws.com",
          "${param.cluster_oidc_provider_url}:sub": "system:serviceaccount:${param.pod_namespace}:${param.pod_namespace}-${param.app}-sa"
        }
      }
    }${idx < length(parameters) - 1 ? "," : ""}
%{ endfor ~}
  ]
}
```

**Custom template** (`trust_policy_templates/custom/{policy}.tftpl`): use this folder
for project-specific trust policies that do not fit the standard templates.

## Available Templates

> The catalogs below are generated from the template files by
> `scripts/generate_template_docs.py`. Do not edit them by hand — run `make docs`
> after adding or changing a template.

### Identity Policy Templates

Naming convention:

- `default`: read and write permissions
- `readonly`: read-only permissions
- `writeonly`: write-only permissions

Some services use domain-specific variant names where they are clearer — for
example, SQS uses `consumer` and `producer`.

Reference an identity template as `service/template` (e.g. `s3/readonly`).

<!-- BEGIN_IDENTITY_TEMPLATES -->
| Service | Template | Description |
|---------|----------|-------------|
| `dynamodb` | `default` | Read and write items in a DynamoDB table and its indexes (get, query, scan, put, update, delete, batch). |
| `dynamodb` | `readonly` | Read items from a DynamoDB table and its indexes (get, query, scan, batch get). |
| `dynamodb` | `writeonly` | Write items to a DynamoDB table (put, update, delete, batch write). |
| `eventbridge` | `default` | Publish events to Amazon EventBridge and describe rules. |
| `kms` | `default` | Encrypt and decrypt with a KMS key, including data key generation and key metadata. |
| `kms` | `readonly` | Decrypt with a KMS key and read key metadata. |
| `kms` | `writeonly` | Encrypt and generate data keys with a KMS key, plus read key metadata. |
| `s3` | `default` | Read and write objects in an S3 bucket (get, put, delete) plus list and locate the bucket. |
| `s3` | `readonly` | Read objects in an S3 bucket (get) plus list and locate the bucket. |
| `s3` | `writeonly` | Write objects to an S3 bucket (put, delete) plus list and locate the bucket. |
| `s3` | `replication` | Source and destination permissions for S3 cross-region replication. Requires the source_bucket parameter. |
| `secretsmanager` | `default` | Read and write a Secrets Manager secret (get, put, update, describe). |
| `secretsmanager` | `readonly` | Read a secret value from Secrets Manager. |
| `secretsmanager` | `writeonly` | Write a Secrets Manager secret (put, update, delete). |
| `sns` | `default` | Publish messages to an SNS topic and read topic attributes. |
| `sqs` | `default` | Send, receive, and delete messages on an SQS queue plus read queue metadata. |
| `sqs` | `consumer` | Consume messages from an SQS queue (receive and delete) plus read queue metadata. |
| `sqs` | `producer` | Produce messages to an SQS queue (send) plus read queue metadata. |
| `ssm` | `default` | Read and write SSM Parameter Store parameters (get, put, delete) plus describe. |
| `ssm` | `readonly` | Read SSM Parameter Store parameters (get, get by path, history) plus describe. |
| `ssm` | `writeonly` | Write SSM Parameter Store parameters (put, delete) plus describe. |
<!-- END_IDENTITY_TEMPLATES -->

### Trust Policy Templates

Reference a trust template by name (e.g. `ec2` or `custom/ec2-lambda`).

<!-- BEGIN_TRUST_TEMPLATES -->
| Template | Description | Parameters |
|----------|-------------|------------|
| `ec2` | Allows EC2 instances to assume the role. | None |
| `event` | Allows EventBridge to assume the role. | None |
| `lambda` | Allows Lambda functions to assume the role. | None |
| `pod` | Allows Kubernetes/OpenShift pods to assume the role via IRSA (OIDC). Renders one statement per parameter entry. | `cluster_oidc_provider_arn`, `cluster_oidc_provider_url`, `pod_namespace`, `app` |
| `s3` | Allows the S3 service to assume the role (e.g. for cross-region replication). | None |
| `step-function` | Allows Step Functions to assume the role. | None |
| `custom/ec2-lambda` | Custom trust policy allowing EC2 and Lambda to assume the role. | None |
| `custom/eventbridge-lambda` | Custom trust policy allowing EventBridge and Lambda to assume the role. | None |
<!-- END_TRUST_TEMPLATES -->

## Adding New Templates

### Add an Identity Policy Template

1. Create the service directory if needed: `identity_policy_templates/{service}/`
2. Create the template file following the naming convention (`default.tftpl`, `readonly.tftpl`, `writeonly.tftpl`).
3. Use the standard JSON format shown in [Template Structure](#template-structure).
4. Add a top-level `"description"` field — the generated catalog uses it (the module ignores it and reads only `.policies`).
5. Consult the [AWS Service Authorization Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/) for the correct actions.
6. Run `make docs` to refresh the catalog in this README.

### Add a Trust Policy Template

1. Standard template: create `trust_policy_templates/{policy}.tftpl`.
2. Custom template: create `trust_policy_templates/custom/{policy}.tftpl`.
3. Use Terraform `templatefile` syntax for dynamic parameters.
4. Add an entry (`description` and `parameters`) to `trust_policy_templates/metadata.json`.
5. Run `make docs` to refresh the catalog in this README.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guidelines and review criteria.

## Validation and Security

### ARN Validation

The module validates that:

- All resources are valid AWS ARNs.
- No wildcard (`*`) is used in resource ARNs.
- ARNs follow the `arn:partition:service:region:account-id:resource` pattern.

### Policy Format Validation

The module validates that:

- The `policy` field follows the `service/policy` format.
- Only lowercase alphanumeric characters are used.

### Best Practices

1. **Least privilege:** use `readonly` or `writeonly` templates when possible.
2. **Specific ARNs:** always provide full ARNs; avoid broad scopes.
3. **Separation of concerns:** create separate policies for different services.
4. **Clear naming:** use descriptive role names that indicate purpose.
5. **Consistent tags:** apply tags for traceability and governance.

## Testing

The module ships with native Terraform tests in [`tests/`](tests/). They use
`mock_provider`, so no AWS credentials are required.

```bash
# Requires Terraform >= 1.7 (mock_provider)
terraform init
terraform test
```

You can also run the standard checks locally with the provided `Makefile`:

```bash
make fmt       # terraform fmt -recursive
make validate  # terraform validate
make test      # terraform test
make lint      # tflint (if installed)
make security  # checkov (if installed)
```

### Continuous integration

A sample GitHub Actions workflow that runs these checks on every pull request is
included at [`.github/workflows/ci.yml.sample`](.github/workflows/ci.yml.sample). It
is **disabled by default**: because this repository is an illustrative sample, the
file uses a `.sample` extension so GitHub Actions does not run it. To enable it in
your own fork, copy it to `.github/workflows/ci.yml`:

```bash
cp .github/workflows/ci.yml.sample .github/workflows/ci.yml
```

## Troubleshooting

#### Error: "The policy field must follow the 'service/policy' format"

Use the `service/policy` format, for example:

```hcl
policy = "s3/default"  # correct
policy = "s3-default"  # incorrect
policy = "S3/default"  # incorrect (use lowercase)
```

#### Error: "Wildcards (*) are not allowed"

Provide full resource ARNs. If you need access to multiple resources, list each ARN
explicitly:

```hcl
resources = [
  "arn:aws:s3:::amzn-s3-demo-bucket-1",
  "arn:aws:s3:::amzn-s3-demo-bucket-2"
]
```

#### Error: "Template file not found"

Confirm the template exists at one of:

- `identity_policy_templates/{service}/{policy}.tftpl`
- `trust_policy_templates/{policy}.tftpl`
- `trust_policy_templates/custom/{policy}.tftpl`

#### Error: "Error assuming role"

1. Verify you are using the correct trust policy template.
2. For pods (EKS/OpenShift), confirm the OIDC parameters are correct.
3. Verify the service account exists in the specified namespace.

### Debugging

```bash
# Inspect the trust policy
aws iam get-role --role-name my-role-name

# Inspect inline policies
aws iam list-role-policies --role-name my-role-name
aws iam get-role-policy --role-name my-role-name --policy-name policy-name

# List attached managed policies
aws iam list-attached-role-policies --role-name my-role-name
```

## Contributing

Contributions are welcome from any team. The maintainers (a central platform or
cloud security team) review every change to keep the module aligned with least
privilege.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to report issues, contribute new
templates, the approval criteria, and the review process. By participating, you
agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Do not report security vulnerabilities through public issues. See
[SECURITY.md](SECURITY.md) for the responsible disclosure process.

## License

Licensed under the [Apache License 2.0](LICENSE). You are free to use, modify, and
distribute this module, subject to the terms of the license.

> This reference implementation ships under Apache 2.0. If your organization prefers
> a different permissive license (for example MIT or MIT-0), replace the `LICENSE`
> file and the copyright holder before publishing.

## References

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Service Authorization Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/)
- [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Terraform AWS Provider - IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [Principle of Least Privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [Building an InnerSource ecosystem using AWS DevOps tools (AWS DevOps Blog)](https://aws.amazon.com/blogs/devops/building-an-innersource-ecosystem-using-aws-devops-tools/)
- [InnerSource Commons](https://innersourcecommons.org/) and its [patterns](https://patterns.innersourcecommons.org/)
- [Trusted Committer pattern](https://patterns.innersourcecommons.org/p/trusted-committer)
- [Base Documentation pattern](https://patterns.innersourcecommons.org/p/base-documentation)
- [An Introduction to InnerSource (GitHub whitepaper)](https://resources.github.com/whitepapers/introduction-to-innersource/)
