# aws-cost-watcher

## What it does

`aws-cost-watcher` pulls daily AWS spend from Cost Explorer, spots spikes against a 7-day rolling average, highlights `Amazon Bedrock` spend, and can optionally send a webhook alert for anomalous days.

## Required environment variables

- `AWS_PROFILE` — optional when you rely on a named profile instead of default credentials
- `AWS_REGION` — required by the helper scripts
- `ALERT_WEBHOOK_URL` — optional; used only by `alert.sh`

## Quick start

```bash
bash skills/aws-cost-watcher/scripts/fetch.sh
bash skills/aws-cost-watcher/scripts/report.sh
bash skills/aws-cost-watcher/scripts/alert.sh cost-report.json
```

## Mock mode note

If Cost Explorer access is denied, `fetch.sh` writes a clearly marked mock `cost-report.json` so the skill remains demo-friendly for local walkthroughs. Mock reports are tagged with `"source": "mock"` and are not suitable for live alerting.

## Alert format

`alert.sh` posts a simple JSON payload shaped like:

```json
{
  "text": "aws-cost-watcher detected 1 anomalous day in us-east-1
- 2025-02-14: total=31.6 avg=19.07"
}
```
