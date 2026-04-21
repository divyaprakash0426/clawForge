# repo-radar

## What it does

Generate a compact repository briefing from manifests, workflows, docs, and source layout.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/brief.py` — builds a read-only repository briefing from the local file tree

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/brief.py` against local inputs and inspect the output before taking action.
