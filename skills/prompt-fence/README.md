# prompt-fence

## What it does

Scan prompt and instruction files for jailbreak phrases, secret exfiltration cues, and unsafe shell patterns.

## Directory contents

- `SKILL.md` — machine-readable skill metadata and runbook
- `COMPAT.md` — compatibility notes for each Claw variant
- `install.sh` — dependency checks for the documented workflow
- `scripts/scan.py` — flags risky prompt text and suspicious shell instructions

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read `COMPAT.md` before enabling the skill on a constrained or sandboxed variant.
3. Run `scripts/scan.py` against local inputs and inspect the output before taking action.
