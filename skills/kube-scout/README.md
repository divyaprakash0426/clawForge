# kube-scout

## What it does

Audit Kubernetes manifests for unsafe defaults, missing limits, and weak image pinning.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/audit.py` — parses YAML manifests and flags high-risk workload settings

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/audit.py` against local inputs and inspect the output before taking action.
