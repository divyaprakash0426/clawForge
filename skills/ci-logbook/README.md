# ci-logbook

## What it does

Summarize CI logs into high-signal failures, warnings, and likely next actions.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/summarize.py` — converts raw CI logs into JSON or markdown triage notes

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/summarize.py` against local inputs and inspect the output before taking action.
