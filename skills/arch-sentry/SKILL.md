---
name: arch-sentry
description: Arch Linux health audits for pacman cache, orphan packages, and pacnew drift.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛠️"
    requires:
      bins: ["pacman", "curl", "jq"]
      env: ["TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["devops", "arch-linux", "system", "automation"]
---

# arch-sentry

## Purpose

Arch Linux health audits for pacman cache, orphan packages, and pacnew drift.

## Runbook

1. Confirm `pacman`, `jq`, and the helper scripts in `scripts/` are available.
2. Abort before continuing if the current user cannot escalate with `sudo`; package cleanup and pacnew reconciliation are intentionally gated.
3. Run `scripts/audit.sh` to collect:
   - pacman package cache size
   - orphan package count and package list
   - `.pacnew` and `.pacsave` drift under `/etc`
4. Use `scripts/run.sh` as the convenience alias when you want the audit plus markdown summary in one step.
5. Review the JSON output and summarize high-signal findings with `scripts/report.sh`.
6. Ask for explicit approval before any cleanup action such as cache pruning, orphan removal, or config-file replacement.
7. If a pacnew file exists, compare it against the active config before recommending merge or replacement steps.

## Stop conditions

1. Abort if `pacman` or `jq` is missing.
2. Abort if the active variant is marked `unsupported`.
3. Abort if `sudo -n true` fails and the next step would require privileges.
4. Abort before any cleanup or file replacement that has not been explicitly approved.

## Output format

- Audit JSON with `cache_size`, `orphan_packages`, and `pacnew_files`
- A markdown summary of immediate issues
- Recommended next actions grouped into safe / needs approval

### Example output

```json
{
  "cache_size": "3.4G",
  "orphan_count": 2,
  "orphan_packages": ["python-jaraco.functools", "qt5-webkit"],
  "pacnew_count": 1,
  "pacnew_files": ["/etc/pacman.conf.pacnew"]
}
```

```md
## arch-sentry report

- pacman cache size: 3.4G
- orphan packages: 2
- pacnew / pacsave files: 1

### Recommended next actions
- Review orphan packages before removal.
- Review pacnew and pacsave files before replacing active configs.
```

## Example invocations

- `skills/arch-sentry/scripts/audit.sh`
- `skills/arch-sentry/scripts/report.sh`
- `skills/arch-sentry/scripts/run.sh`
- "Run arch-sentry and tell me whether pacman cache cleanup is worth doing today."
    
