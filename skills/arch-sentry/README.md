# arch-sentry

## What it does

`arch-sentry` audits an Arch Linux host for the three cleanup tasks operators usually postpone: oversized pacman cache directories, orphaned packages, and `.pacnew` / `.pacsave` drift inside `/etc`.

## Directory contents

- `SKILL.md` — machine-readable metadata plus the operational runbook
- `COMPAT.md` — Claw variant compatibility notes with Arch-specific caveats
- `install.sh` — dependency checks for `pacman`, `jq`, and notification prerequisites
- `scripts/audit.sh` — read-only JSON audit of cache, orphans, and pacnew drift
- `scripts/report.sh` — markdown formatter for the audit snapshot
- `scripts/run.sh` — convenience wrapper that runs the report flow end to end

## Quick start

```bash
bash skills/arch-sentry/scripts/audit.sh | jq .
bash skills/arch-sentry/scripts/report.sh
```

## Sample output

```json
{
  "cache_size": "3.4G",
  "orphan_count": 2,
  "orphan_packages": [
    "python-jaraco.functools",
    "qt5-webkit"
  ],
  "pacnew_count": 1,
  "pacnew_files": [
    "/etc/pacman.conf.pacnew"
  ]
}
```

## Security notes

- The audit path is read-only and safe to run without making host changes.
- Any cleanup step that would touch pacman state or replace files under `/etc` is intentionally gated behind explicit operator approval.
- `sudo` is mentioned because package cache pruning, orphan removal, and config reconciliation are privileged operations on a live host; the skill stops before those actions unless the operator clearly opts in.
    
