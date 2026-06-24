# Contributing

Thanks for your interest in improving this module. It is developed using an
**InnerSource** model: the **maintainers** (a central platform or cloud security
team) own the module and review every change, while any application or workload team
can use it and propose changes through pull requests.

By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Collaboration Model

```
+-------------------------------------------------------------+
|                  Maintainers (central team)                 |
|  - Own and version the module                               |
|  - Review all contributions                                 |
|  - Approve new templates                                    |
|  - Keep templates aligned with least privilege              |
+-------------------------------------------------------------+
                            ^
                            | Pull Requests (review required)
                            |
+-------------------------------------------------------------+
|                Application / Workload teams                 |
|  - Use the module in their projects                         |
|  - Contribute new policy templates                          |
|  - Report issues and request features                       |
+-------------------------------------------------------------+
```

## Ways to Contribute

### 1. Report an Issue

1. Open an issue in the repository (use the provided issue templates).
2. Describe the problem or request clearly.
3. Include code examples when relevant.
4. Wait for feedback from the maintainers.

For **security vulnerabilities**, do not open a public issue. Follow the process in
[SECURITY.md](SECURITY.md).

### 2. Contribute a New Template

If the existing templates do not meet your needs, contribute a new one.

1. **Identify the need**
   - Check whether a similar template already exists.
   - Document the specific use case.
   - Identify the minimum required permissions.

2. **Create the template**
   - Follow the structure of existing templates.
   - Use only the strictly necessary permissions (least privilege).
   - Consult the [AWS Service Authorization Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/) for correct actions.

3. **Test locally** (see [Local Development](#local-development)).

4. **Open a Pull Request**
   - Create a descriptive branch (e.g. `feat/add-rds-readonly-template`).
   - Include the new template (with a `description` field for identity templates, or a `metadata.json` entry for trust templates).
   - Run `make docs` to regenerate the README catalog (do not edit the generated tables by hand).
   - Update `CHANGELOG.md`.
   - Describe the use case and justify each permission in the PR description.

## Local Development

Requirements: Terraform >= 1.3 to use the module; Terraform >= 1.7 to run the tests
(`mock_provider`). Optional tooling: `tflint`, `checkov`.

Run the same checks CI runs:

```bash
make fmt       # terraform fmt -recursive
make validate  # terraform init -backend=false && terraform validate
make examples  # validate the examples/
make test      # terraform test  (uses mock_provider, no AWS credentials needed)
make lint      # tflint   (skipped if not installed)
make security  # checkov  (skipped if not installed)
make all       # run everything
```

Or run the commands directly:

```bash
terraform fmt -recursive -check
terraform init -backend=false
terraform validate
terraform test
```

## Template Guidelines

### Identity Policy Templates

Required structure:

```json
{
  "description": "Short summary shown in the generated README catalog.",
  "policies": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "DescriptiveSid",
        "Effect": "Allow",
        "Action": ["service:Action1", "service:Action2"],
        "Resource": ["{{RESOURCE_ARN}}"]
      }
    ]
  },
  "managed_policies": []
}
```

The top-level `description` is required: it feeds the generated README catalog and is
ignored by the Terraform module (which reads only `.policies`). After adding or
changing templates, run `make docs`.

Naming convention:

- `default.tftpl` - read AND write permissions
- `readonly.tftpl` - read-only permissions
- `writeonly.tftpl` - write-only permissions

Placeholders: `{{RESOURCE_ARN}}`, `{{RESOURCE_ARN}}/*`, and `{{<parameter>}}` (filled
from the identity policy `parameters` map).

Security principles:

1. **Least privilege:** include only strictly necessary permissions.
2. **Separation of concerns:** create separate `readonly`/`writeonly` templates when possible.
3. **Documentation:** use a `Sid` and comment non-obvious permissions.
4. **Validation:** always confirm actions against official AWS documentation.

### Trust Policy Templates

Simple template (`trust_policy_templates/{policy}.tftpl`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "service.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Parameterized templates render one statement per entry in `trust_policy.parameters`
using Terraform `templatefile` syntax. Custom, project-specific trust policies go
under `trust_policy_templates/custom/`.

## Approval Criteria

The maintainers evaluate contributions against:

**Security**

- Follows the principle of least privilege.
- No unnecessary permissions.
- No wildcards in actions without justification.
- No administrative access granted.

**Quality**

- Valid JSON syntax.
- Follows the existing template structure.
- Clear documentation of purpose.
- Correct action names per AWS documentation.
- `terraform fmt`, `validate`, and `test` pass in CI.

**Usefulness**

- Addresses a real use case.
- Does not duplicate an existing template.
- Reusable by other teams.

## Review Process

1. **Initial review:** syntax, structure, naming, and documentation.
2. **Security analysis:** least privilege, permission verification against AWS docs, risk analysis, and use-case validation.
3. **Feedback and iteration:** the maintainers provide detailed feedback and may request changes.
4. **Approval and merge:** final approval by the maintainers, merge to the main branch, and changelog update.

Set service-level expectations (for example, a target first-response time) that fit
your organization, and document them here so contributors know what to expect.

## Enforcing Review

Require maintainer approval before merging by configuring branch protection on your
platform:

- **GitHub / GitLab:** protect the default branch, require pull request reviews, and
  require review from Code Owners (see [`CODEOWNERS`](CODEOWNERS)).
- **AWS CodeCommit:** attach an
  [approval rule template](https://docs.aws.amazon.com/codecommit/latest/userguide/approval-rule-templates.html)
  that requires approval from the maintainers before a pull request can be merged.

Run the automated checks (`fmt`, `validate`, `test`, `tflint`, `checkov`) on every
pull request. The bundled GitHub Actions workflow does this; on AWS-native stacks you
can run the same commands in AWS CodeBuild triggered by CodeCommit pull requests.

## Pull Request Description Example

```markdown
## New Template: RDS Read-Only

### Use Case
Applications that only need to read RDS instance information without
modifying configuration or data.

### Permissions Included
- rds:DescribeDBInstances - list instances
- rds:DescribeDBClusters - list clusters
- rds:ListTagsForResource - read tags

### Permissions Excluded (and why)
- rds:ModifyDBInstance - not needed for read access
- rds:DeleteDBInstance - not needed for read access

### Testing
- Validated JSON syntax
- terraform fmt / validate / test pass
- Confirmed the application can read RDS and cannot modify it
```

## Maintainers

This module is owned by a central team acting as trusted committers. Replace the
placeholders in [`CODEOWNERS`](CODEOWNERS) with your organization's actual team
handle so that pull requests automatically request review from the right people.
