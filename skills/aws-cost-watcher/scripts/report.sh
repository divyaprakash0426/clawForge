#!/usr/bin/env bash
set -euo pipefail

report_file="${1:-cost-report.json}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$report_file" ]; then
  "$SCRIPT_DIR/fetch.sh"
fi

printf '## aws-cost-watcher daily digest

'
printf -- '- Source: `%s`
' "$(jq -r '.source' "$report_file")"
printf -- '- Window: `%s` → `%s`
' "$(jq -r '.window.start' "$report_file")" "$(jq -r '.window.end' "$report_file")"
printf -- '- Bedrock total: `%s`

' "$(jq -r '.summary.bedrock_total' "$report_file")"

printf '| Date | Total (USD) | 7d avg | Bedrock | Services | Anomaly |
| --- | ---: | ---: | ---: | --- | --- |
'
jq -r '.days[] | "| \(.date) | \(.total) | \(.rolling_average) | \(.bedrock) | \(.services | to_entries | map("\(.key)=\(.value)") | join("<br>")) | \(if .anomalous then "⚠️ yes" else "no" end) |"' "$report_file"

printf '
### Anomaly highlights

'
anomaly_lines="$(jq -r '.summary.anomalous_days[]? | "- \(.date): total=\(.total) vs avg=\(.rolling_average) (Bedrock=\(.bedrock))"' "$report_file")"
if [ -n "$anomaly_lines" ]; then
  printf '%s
' "$anomaly_lines"
else
  echo '- No anomalous days detected in the current window.'
fi
