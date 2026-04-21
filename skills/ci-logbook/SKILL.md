---
name: ci-logbook
description: Summarize CI logs into high-signal failures, warnings, and likely next actions.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛠️"
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
      ironclaw: partial
    security_tier: L1
    tags: ['devops', 'ci', 'logs', 'triage']
---

# ci-logbook

## Purpose

Turn raw CI or workflow logs into a concise incident-style brief with the first real errors up front.

## Runbook

1. Collect one or more local CI log files or paste log text through stdin.
2. Run `scripts/summarize.py` to extract error counts, warning counts, traceback markers, and representative lines.
3. Review the first-failure excerpts before proposing reruns or fixes; the goal is diagnosis, not blind retries.
4. Share either the JSON payload or markdown summary with the operator.

## Stop conditions

1. Abort if the logs are incomplete or obviously truncated before the failure point.
2. Abort before recommending destructive cleanup or credential rotation from log text alone.
3. Abort if the current variant cannot access the required local log files.

## Output format

- Per-file counts for errors, warnings, failures, and traceback markers
- First high-signal excerpts with line numbers
- A short next-actions section

## Example invocations

- `python3 skills/ci-logbook/scripts/summarize.py .github/logs/build.log --markdown`
- `cat build.log | python3 skills/ci-logbook/scripts/summarize.py -`
