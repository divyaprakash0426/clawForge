---
name: prompt-fence
description: Scan prompt and instruction files for jailbreak phrases, secret exfiltration cues, and unsafe shell patterns.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛡️"
    requires:
      bins: ['python3']
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
    tags: ['security', 'prompts', 'jailbreaks', 'audit']
---

# prompt-fence

## Purpose

Catch risky prompt text before it gets bundled into skills, system prompts, or operator playbooks.

## Runbook

1. Scan one file, one directory, or a narrowed skill subtree rather than an entire home directory.
2. Run `scripts/scan.py` to flag common jailbreak phrases, data exfiltration requests, and unsafe shell habits.
3. Review each finding in context; a match is a lead for review, not automatic proof of malicious intent.
4. Escalate only the lines that clearly weaken instruction boundaries or leak secrets.

## Stop conditions

1. Abort if the scan target includes private data that should not be copied into reports.
2. Abort before classifying a file as malicious without manual review.
3. Abort if the current variant cannot safely inspect the relevant local files.

## Output format

- File-by-file finding inventory
- Severity, rule name, line number, and matched excerpt
- A concise markdown or JSON review artifact

## Example invocations

- `python3 skills/prompt-fence/scripts/scan.py skills/`
- `python3 skills/prompt-fence/scripts/scan.py README.md --markdown`
