# permission-lens

## What it does

`permission-lens` reads a skill's frontmatter and turns it into a clear permission manifest: required tools, required environment variables, risk tier, compatibility matrix, and a plain-English explanation of what the skill is allowed to touch.

## Quick start

```bash
python3 skills/permission-lens/scripts/inspect.py skills/arch-sentry/SKILL.md
python3 skills/permission-lens/scripts/inspect.py skills/tf-copilot/SKILL.md --format json
```

## Risk tiers explained

- `L1` — read-only or inspection-oriented behavior
- `L2` — writes to disk, containers, or other local / network-managed state
- `L3` — interacts with credentials, production systems, or cloud control planes

## Sample text output

```text
permission manifest: aws-cost-watcher
security tier: L3 (red)
required bins: aws (AWS API access), jq (JSON processing), curl (outbound HTTP)
credentials: AWS_PROFILE, AWS_REGION, ALERT_WEBHOOK_URL
```

## Integration with `install-skill.sh`

Run `permission-lens` before `./install-skill.sh <skill-name>` when you want a human-readable approval gate for a skill's requested capabilities.
