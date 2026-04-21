# dep-hygiene

## What it does

Inspect dependency manifests for missing lockfiles, loose pins, and risky git or path sources.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/audit.py` — scans common dependency manifests and reports hygiene risks

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/audit.py` against local inputs and inspect the output before taking action.
