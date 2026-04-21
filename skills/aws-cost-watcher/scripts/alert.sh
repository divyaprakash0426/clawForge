#!/usr/bin/env bash
set -euo pipefail

report_file="${1:-cost-report.json}"

if [ ! -f "$report_file" ]; then
  echo "Report file not found: $report_file" >&2
  exit 1
fi

if [ -z "${ALERT_WEBHOOK_URL:-}" ]; then
  echo "Warning: ALERT_WEBHOOK_URL is not set; skipping alert delivery."
  exit 0
fi

if [ "$(jq -r '.source' "$report_file")" = "mock" ]; then
  echo "Warning: report source is mock; no alert sent."
  exit 0
fi

anomaly_count="$(jq '.summary.anomalous_days | length' "$report_file")"
if [ "$anomaly_count" -eq 0 ]; then
  echo "No anomalous days detected; alert not sent."
  exit 0
fi

alert_text="aws-cost-watcher detected $anomaly_count anomalous day(s) in $(jq -r '.region' "$report_file")"
while IFS= read -r line; do
  alert_text="${alert_text}
${line}"
done < <(jq -r '.summary.anomalous_days[] | "- \(.date): total=\(.total) avg=\(.rolling_average) bedrock=\(.bedrock)"' "$report_file")

payload="$(jq -n --arg text "$alert_text" '{text: $text}')"
status_code="$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d "$payload" "$ALERT_WEBHOOK_URL" || true)"

if printf '%s' "$status_code" | grep -Eq '^2'; then
  echo "Alert posted successfully (HTTP $status_code)."
else
  echo "Webhook returned HTTP $status_code." >&2
  exit 1
fi
