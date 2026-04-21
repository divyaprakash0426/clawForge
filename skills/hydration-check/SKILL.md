---
name: hydration-check
description: Summarize local water-intake logs and flag low-intake streaks against a daily target.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🏸"
    requires:
      bins: ['python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: full
      nullclaw: partial
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ['health', 'hydration', 'tracking', 'wellness']
---

# hydration-check

## Purpose

Turn simple hydration logs into a quick weekly signal without sending health data to the cloud.

## Runbook

1. Provide a CSV file or stdin with at least `date` and `ml` columns.
2. Run `scripts/report.py` with an explicit daily target that fits the operator context.
3. Review the weekly average and below-target streaks before suggesting behavior changes.
4. Keep outputs local because hydration logs still count as personal health data.

## Stop conditions

1. Abort if the input log is incomplete or mixes incompatible units.
2. Abort before giving medical guidance beyond simple hydration tracking.
3. Abort if the active variant cannot safely keep the health data local.

## Output format

- Daily totals
- Seven-day average intake
- Below-target streak information

## Example invocations

- `python3 skills/hydration-check/scripts/report.py water.csv --target-ml 2500`
- `cat hydration.csv | python3 skills/hydration-check/scripts/report.py - --markdown`
