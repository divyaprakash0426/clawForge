# ClawForge `SKILL.md` format

Each ClawForge skill uses YAML frontmatter followed by a runbook-oriented markdown body.

## Required structure

```yaml
---
name: arch-sentry
description: Arch Linux system health monitor with chat-driven cleanup approvals.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🦞"
    requires:
      bins: ["pacman", "curl"]
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: [devops, arch-linux, system, automation]
---
```

## Field reference

| Field | Required | Notes |
| --- | --- | --- |
| `name` | Yes | Lowercase kebab-case skill identifier. |
| `description` | Yes | One-line purpose statement. |
| `version` | Yes | Semantic version string. |
| `metadata.openclaw.emoji` | Yes | Human-facing icon for catalogs and UIs. |
| `metadata.openclaw.requires.bins` | Yes | Binaries required to execute the skill. |
| `metadata.openclaw.requires.env` | Yes | Environment variables or secrets the skill needs. |
| `metadata.openclaw.primaryEnv` | Recommended | Primary runtime environment or `null`. |
| `metadata.openclaw.compat.*` | Yes | `full`, `partial`, or `unsupported` for all variants. |
| `metadata.openclaw.security_tier` | Yes | `L1`, `L2`, or `L3`. |
| `metadata.openclaw.tags` | Yes | Non-empty list of searchable tags. |

## Body conventions

The markdown body should stay operational and structured:

1. **Purpose** — what the skill is for
2. **Runbook** — ordered steps the operator or agent should follow
3. **Stop conditions** — explicit abort points
4. **Output format** — what the skill should emit
5. **Examples** — a few clear invocation patterns

## Compatibility rules

- Use `full` only when the skill runs as documented.
- Use `partial` when the workflow is still useful with limitations.
- Use `unsupported` when the variant cannot safely or realistically perform the workflow.

Document the reason for any non-`full` status in `COMPAT.md`.
