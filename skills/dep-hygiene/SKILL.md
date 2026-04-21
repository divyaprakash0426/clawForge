---
name: dep-hygiene
description: Inspect dependency manifests for missing lockfiles, loose pins, and risky git or path sources.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛡️"
    requires:
      bins: ['python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: partial
      nanobot: full
      ironclaw: full
    security_tier: L1
    tags: ['security', 'dependencies', 'lockfiles', 'supply-chain']
---

# dep-hygiene

## Purpose

Flag dependency hygiene gaps that raise supply-chain risk before code is built or deployed.

## Runbook

1. Run the audit from a repository root or a narrowed subdirectory.
2. Let `scripts/audit.py` discover common manifests such as package.json, requirements.txt, pyproject.toml, Cargo.toml, and go.mod.
3. Review missing lockfiles first, then inspect loose version ranges and git/path-based sources.
4. Use the output to plan dependency tightening; the script is intentionally read-only.

## Stop conditions

1. Abort if the repository uses a package manager that the built-in rules do not understand.
2. Abort before calling a dependency malicious based solely on a loose pin or local path reference.
3. Abort if the target variant cannot safely read the repository tree.

## Output format

- Repository-wide manifest inventory
- Risk findings grouped by manifest path and rule
- Lockfile coverage summary

## Example invocations

- `python3 skills/dep-hygiene/scripts/audit.py .`
- `python3 skills/dep-hygiene/scripts/audit.py services/api --markdown`
