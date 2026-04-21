# changelog-weaver

## What it does

Turn git history into release-note sections grouped by conventional commit intent.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/build.py` — converts git history into a draft markdown changelog

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/build.py` against local inputs and inspect the output before taking action.
