---
name: permission-lens
description: Human-readable permission manifest and risk explanation for any skill.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🔍"
    requires:
      bins: ["sed", "awk", "python3"]
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
    tags: ["security", "permissions", "audit", "manifest"]
---

# permission-lens

## Purpose

Human-readable permission manifest and risk explanation for any skill.

## Runbook

1. Run `scripts/inspect.py [SKILL_MD_PATH]` to parse a target `SKILL.md`.
2. The script reads the YAML frontmatter and extracts required bins, required env vars, `security_tier`, compat matrix, and tags.
3. Apply L1 / L2 / L3 risk scoring: L1 = read-only (green), L2 = writes to disk or network (amber), L3 = uses credentials or prod systems (red).
4. Map each required bin to a risk category such as `curl` = network access, `sudo` = privilege escalation, and `rm` = destructive file ops.
5. Output a human-readable permission manifest describing what the skill can read, write, call out to, and what credentials it expects.
6. Output a machine-readable JSON manifest for use by `install-skill.sh` or other install-time tooling.

## Stop conditions

1. Abort if `TARGET_PATH` does not exist or is not a valid `SKILL.md` file.
2. Abort if `python3` is unavailable.
3. Abort if the YAML frontmatter cannot be parsed.

## Output format

- JSON manifest: `{skill, security_tier, risk_label, bins_risk, env_risk, compat, plain_english_summary}`
- Console: formatted permission manifest block with color indicators where ANSI color is supported

## Example invocations

- `python3 skills/permission-lens/scripts/inspect.py skills/arch-sentry/SKILL.md`
- `python3 skills/permission-lens/scripts/inspect.py skills/tf-copilot/SKILL.md --format json`
- `python3 skills/permission-lens/scripts/inspect.py skills/aws-cost-watcher/SKILL.md --format text`
- "Show me the permission manifest for aws-cost-watcher before I install it."
