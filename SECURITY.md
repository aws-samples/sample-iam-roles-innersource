# Reporting Security Issues

Amazon Web Services (AWS) is dedicated to the responsible disclosure of security vulnerabilities.

We kindly ask that you do not open a public GitHub issue to report security concerns.

Instead, please submit the issue to the AWS Vulnerability Disclosure Program via HackerOne or send your report via email.

For more details, visit the AWS Vulnerability Reporting Page.

Thank you in advance for collaborating with us to help protect our customers.

--

# Sample SECURITY.md

# Security Policy

This module provisions AWS IAM roles and policies, so security is a first-class
concern. We appreciate responsible disclosure of any vulnerability.

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues, pull
requests, or discussions.**

Instead, report them privately to the maintainers:

- Email: `security@example.com`

> Replace the address above with your organization's security contact before
> publishing. If you host on GitHub, you can also enable private vulnerability
> reporting and direct reporters there.

Please include as much of the following as you can:

- A description of the issue and its impact.
- The affected file(s), template(s), or input(s).
- Steps to reproduce (for example, a minimal module configuration).
- Any suggested remediation.

## What to Expect

- We will acknowledge your report and begin investigating.
- We will keep you informed of progress toward a fix.
- We will coordinate a disclosure timeline with you and credit you if you wish.

## Scope

Examples of issues that are in scope:

- A template that grants more permissions than its name implies (for example, a
  `readonly` template that allows writes).
- A validation gap that allows wildcards or malformed ARNs to reach a generated
  policy.
- A trust policy template that is overly permissive about who can assume the role.

## Using This Module Securely

- Pin the module to a specific version or commit.
- Review the rendered IAM policies before applying in production.
- Prefer `readonly`/`writeonly` templates over `default` when possible.
- Keep wildcards out of resource ARNs (the module enforces this).
