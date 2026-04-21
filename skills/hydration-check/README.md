# hydration-check

## What it does

Summarize local water-intake logs and flag low-intake streaks against a daily target.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/report.py` — converts hydration CSV logs into daily totals and streak summaries

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/report.py` against local inputs and inspect the output before taking action.
