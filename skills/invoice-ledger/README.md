# invoice-ledger

## What it does

Age invoice CSV exports into overdue buckets and cash-collection summaries.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/age.py` — builds a local accounts-receivable aging report from CSV data

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/age.py` against local inputs and inspect the output before taking action.
