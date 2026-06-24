---
name: New template request
about: Request a new identity or trust policy template
title: "[Template] "
labels: enhancement
---

## Template Type

- [ ] Identity policy template (e.g. `rds/readonly`)
- [ ] Trust policy template (e.g. `glue`)

## Use Case

The real-world scenario this template supports.

## Proposed Permissions / Principals

For an identity policy, list the AWS actions and why each is needed.
For a trust policy, list the principal(s) that should assume the role.

```
service:Action1 - reason
service:Action2 - reason
```

## Access Type

- [ ] default (read and write)
- [ ] readonly
- [ ] writeonly
- [ ] n/a (trust policy)

## Additional Context

Links to AWS documentation or anything else relevant. Consider opening a pull
request with the template (see CONTRIBUTING.md).
