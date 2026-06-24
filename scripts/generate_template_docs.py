#!/usr/bin/env python3
"""Generate the template catalog tables in README.md from the template files.

Identity policy templates are self-documenting: each
identity_policy_templates/<service>/<type>.tftpl must carry a top-level
"description" field. The Terraform module ignores it (it reads only ".policies"),
so it is safe metadata that travels with the template in the same pull request.

Trust policy templates are raw IAM JSON and some are Terraform templatefiles, so
they cannot embed a description safely. Their descriptions live in
trust_policy_templates/metadata.json instead.

The default managed policies table is generated from
identity_policy_templates/default_managed_policies.json.

Usage:
  python3 scripts/generate_template_docs.py           # rewrite README.md in place
  python3 scripts/generate_template_docs.py --check    # exit non-zero if stale
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
IDENTITY_DIR = ROOT / "identity_policy_templates"
TRUST_DIR = ROOT / "trust_policy_templates"
TRUST_METADATA = TRUST_DIR / "metadata.json"
DEFAULT_MANAGED_POLICIES = IDENTITY_DIR / "default_managed_policies.json"

# Ordering of template variants within a service.
TYPE_ORDER = {"default": 0, "readonly": 1, "writeonly": 2, "replication": 3, "consumer": 4, "producer": 5}


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(2)


def build_identity_table():
    rows = []
    for path in sorted(IDENTITY_DIR.glob("*/*.tftpl")):
        service = path.parent.name
        template = path.stem
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError as exc:
            fail(f"{path}: invalid JSON ({exc})")
        description = data.get("description")
        if not description:
            fail(
                f'{path}: missing top-level "description" field. Every identity '
                "policy template must describe itself."
            )
        rows.append((service, template, description))

    rows.sort(key=lambda row: (row[0], TYPE_ORDER.get(row[1], 99), row[1]))

    lines = [
        "| Service | Template | Description |",
        "|---------|----------|-------------|",
    ]
    lines += [f"| `{s}` | `{t}` | {d} |" for s, t, d in rows]
    return "\n".join(lines)


def build_trust_table():
    if not TRUST_METADATA.exists():
        fail(f"missing {TRUST_METADATA}")
    metadata = json.loads(TRUST_METADATA.read_text())

    names = [p.stem for p in sorted(TRUST_DIR.glob("*.tftpl"))]
    names += ["custom/" + p.stem for p in sorted((TRUST_DIR / "custom").glob("*.tftpl"))]

    lines = [
        "| Template | Description | Parameters |",
        "|----------|-------------|------------|",
    ]
    for name in names:
        meta = metadata.get(name)
        if meta is None:
            fail(f"trust template '{name}' has no entry in {TRUST_METADATA.name}")
        params = meta.get("parameters") or []
        params_text = ", ".join(f"`{p}`" for p in params) if params else "None"
        lines.append(f"| `{name}` | {meta['description']} | {params_text} |")
    return "\n".join(lines)


def build_managed_policies_table():
    if not DEFAULT_MANAGED_POLICIES.exists():
        fail(f"missing {DEFAULT_MANAGED_POLICIES}")
    data = json.loads(DEFAULT_MANAGED_POLICIES.read_text())

    lines = [
        "| Trust Policy | Managed Policies Applied |",
        "|--------------|--------------------------|",
    ]
    for trust_type in sorted(data):
        arns = data[trust_type] or []
        applied = "<br>".join(f"`{arn}`" for arn in arns) if arns else "None"
        lines.append(f"| `{trust_type}` | {applied} |")
    return "\n".join(lines)


def replace_block(text, marker, body):
    begin = f"<!-- BEGIN_{marker} -->"
    end = f"<!-- END_{marker} -->"
    pattern = re.compile(re.escape(begin) + ".*?" + re.escape(end), re.DOTALL)
    if not pattern.search(text):
        fail(f"marker block {begin} ... {end} not found in README.md")
    return pattern.sub(lambda _match: f"{begin}\n{body}\n{end}", text)


def main():
    check = "--check" in sys.argv[1:]
    original = README.read_text()
    updated = replace_block(original, "IDENTITY_TEMPLATES", build_identity_table())
    updated = replace_block(updated, "TRUST_TEMPLATES", build_trust_table())
    updated = replace_block(updated, "MANAGED_POLICIES", build_managed_policies_table())

    if updated == original:
        print("README template catalog already up to date.")
        return
    if check:
        print(
            "README template catalog is stale. Run: "
            "python3 scripts/generate_template_docs.py",
            file=sys.stderr,
        )
        sys.exit(1)
    README.write_text(updated)
    print("Updated README template catalog.")


if __name__ == "__main__":
    main()
