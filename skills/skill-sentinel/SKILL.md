---
name: skill-sentinel
description: Pre-install scan for prompt injection, exfiltration patterns, and risky shell usage.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛡️"
    requires:
      bins: ["grep", "awk", "sed", "python3"]
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
    tags: ["security", "scanner", "supply-chain", "review"]
---

# skill-sentinel

## Purpose

Pre-install scan for prompt injection, exfiltration patterns, and risky shell usage.

## Runbook

1. Accept a local `SKILL.md` path or a remote URL that resolves to a candidate skill definition.
2. Fetch the target content and extract high-risk command and prompt patterns.
3. Flag the following categories explicitly:
   - `curl` or `wget` fetching from raw IPs
   - shell piping into `sh` or `bash`
   - `base64` decoding or opaque payload execution
   - environment-variable reads that target secrets or tokens
   - suspicious networking helpers commonly used for reverse shells or ad-hoc tunnels
   - prompt-injection phrases that try to override system instructions
4. Emit a JSON report containing findings, total risk score, and a `blocked` boolean.
5. Block installation when `risk_score > 7`.
6. Exit code semantics: `0` means the target is installable, `1` means the target is blocked and installation should stop.

## Stop conditions

1. Abort if `python3` is unavailable.
2. Abort if the active variant is marked `unsupported`.
3. Abort installation immediately when the report is `blocked`.

## Output format

- JSON report with `target`, `risk_score`, `blocked`, and `findings`
- Text mode summary for CI logs and operator review
- Recommended next actions based on the highest-severity findings

### Example output

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

## Example invocations

- `python3 skills/skill-sentinel/scripts/scan.py skills/arch-sentry/SKILL.md`
- `python3 skills/skill-sentinel/scripts/scan.py --format text https://example.com/SKILL.md`
- "Scan this SKILL.md before installing it and tell me if it should be blocked."
    
