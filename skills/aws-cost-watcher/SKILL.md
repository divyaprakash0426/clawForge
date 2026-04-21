---
name: aws-cost-watcher
description: Daily AWS spend anomaly watcher with Bedrock cost correlation.
version: 1.0.0
metadata:
  openclaw:
    emoji: "💰"
    requires:
      bins: ["aws", "jq", "curl"]
      env: ["AWS_PROFILE", "AWS_REGION", "ALERT_WEBHOOK_URL"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["devops", "aws", "cost", "finops"]
---

# aws-cost-watcher

## Purpose

Daily AWS spend anomaly watcher with Bedrock cost correlation.

## Runbook

1. Run `scripts/fetch.sh` to pull daily cost data from AWS Cost Explorer (last 14 days by default).
2. The script compares each day of spend against the trailing 7-day rolling average to detect anomalies.
3. Flag a day as anomalous if spend is greater than `1.5×` the rolling average.
4. Correlate with Bedrock API spend if the active AWS profile can see the `Amazon Bedrock` service line item.
5. Run `scripts/alert.sh` if any anomalous day is found; it sends a formatted alert to `ALERT_WEBHOOK_URL`.
6. Always produce a local report via `scripts/report.sh` regardless of alert status.

## Stop conditions

1. Abort if `aws` CLI is not configured (`aws sts get-caller-identity` fails).
2. Abort if `AWS_REGION` is not set.
3. Do not send alerts if `ALERT_WEBHOOK_URL` is not set; log a warning and continue.
4. Abort live collection if the Cost Explorer API returns an access denied error.

## Output format

- `cost-report.json` — daily costs per service for the lookback window
- Console: markdown table of spend per day, anomaly flags, and Bedrock spend
- Alert payload: JSON posted to `ALERT_WEBHOOK_URL`

## Example invocations

- `bash skills/aws-cost-watcher/scripts/fetch.sh`
- `bash skills/aws-cost-watcher/scripts/fetch.sh --days 30`
- `bash skills/aws-cost-watcher/scripts/alert.sh cost-report.json`
- `bash skills/aws-cost-watcher/scripts/report.sh`
- "Show me my AWS spend anomalies for the past two weeks."
