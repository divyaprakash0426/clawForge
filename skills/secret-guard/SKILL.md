---
name: secret-guard
description: Secret scanning wrapper for repositories and skill configs.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🔐"
    requires:
      bins: ["git", "gitleaks", "trufflehog", "jq"]
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: full
    security_tier: L1
    tags: ["security", "secrets", "scan", "compliance"]
---

# secret-guard

## Purpose

Secret scanning wrapper for repositories and skill configs.

## Runbook

1. Run `scripts/scan.sh [TARGET_PATH]` (default: current directory).
2. The script attempts to use `gitleaks` if available, else falls back to `trufflehog`, else uses built-in regex patterns.
3. Scan scope includes git-tracked files, `SKILL.md` files, `.env` files, and shell scripts.
4. Findings are written to `secret-findings.json`.
5. Run `scripts/report.sh` to produce a markdown summary of findings with remediation guidance.
6. Never print secret values; truncate matched strings to the first 6 characters plus `***`.

## Stop conditions

1. Abort if `TARGET_PATH` does not exist.
2. Abort if no scanning tool is available and the built-in regex scan also fails.
3. Never write secret values to disk or logs; always mask.
4. Abort if the active variant is unsupported.

## Output format

- `secret-findings.json` — findings: `[{tool, file, line, rule_id, severity, masked_value}]`
- Console: markdown summary with finding count by severity and remediation steps

## Example invocations

- `bash skills/secret-guard/scripts/scan.sh .`
- `bash skills/secret-guard/scripts/scan.sh /path/to/repo`
- `bash skills/secret-guard/scripts/report.sh secret-findings.json`
- "Scan this repository for accidentally committed secrets."
