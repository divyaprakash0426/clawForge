# thumbnail-lab

## What it does

Turn a short script into reusable thumbnail hooks, overlay copy, and shot prompts.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/spec.py` — generates a thumbnail planning sheet from script text

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/spec.py` against local inputs and inspect the output before taking action.
