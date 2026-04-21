#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: fetch.sh [--days N] [--mock]

Pull AWS daily spend data from Cost Explorer and write cost-report.json.
EOF
}

days=14
force_mock=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      days="${2:-}"
      shift 2
      ;;
    --mock)
      force_mock=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if ! [[ "$days" =~ ^[0-9]+$ ]] || [ "$days" -le 0 ]; then
  echo "--days must be a positive integer." >&2
  exit 1
fi

for bin in aws jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "aws-cost-watcher requires $bin." >&2
    exit 1
  fi
done

if [ "$force_mock" -ne 1 ] && [ -z "${AWS_REGION:-}" ]; then
  echo "AWS_REGION must be set." >&2
  exit 1
fi

start_date="$(date -u -d "$days days ago" +%F)"
end_date="$(date -u +%F)"
source_mode="aws"
base_days='[]'

if [ "$force_mock" -eq 1 ]; then
  source_mode="mock"
else
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "aws sts get-caller-identity failed. Configure AWS credentials before running fetch.sh." >&2
    exit 1
  fi

  ce_output="$(aws ce get-cost-and-usage             --time-period Start="$start_date",End="$end_date"             --granularity DAILY             --metrics UnblendedCost             --group-by Type=DIMENSION,Key=SERVICE             --output json 2>&1)" || ce_status=$?
  ce_status="${ce_status:-0}"

  if [ "$ce_status" -ne 0 ]; then
    if printf '%s' "$ce_output" | grep -qi 'AccessDenied'; then
      echo 'MOCK: Cost Explorer access denied; writing a demo cost-report.json instead.' >&2
      source_mode="mock"
    else
      printf '%s
' "$ce_output" >&2
      exit "$ce_status"
    fi
  else
    base_days="$(printf '%s' "$ce_output" | jq -c '[.ResultsByTime[] | {
      date: .TimePeriod.Start,
      total: (([.Groups[]? | (.Metrics.UnblendedCost.Amount | tonumber)] | add) // 0),
      bedrock: (([.Groups[]? | select(.Keys[0] == "Amazon Bedrock") | (.Metrics.UnblendedCost.Amount | tonumber)] | add) // 0),
      services: (reduce .Groups[]? as $group ({}; .[$group.Keys[0]] = (($group.Metrics.UnblendedCost.Amount // "0") | tonumber)))
    }]')"
  fi
fi

if [ "$source_mode" = "mock" ]; then
  mock_totals=(18.70 19.10 18.95 19.25 18.80 19.40 19.05 31.60 20.10 20.55 21.05 20.80 21.30 21.10)
  mock_objects=()
  for ((offset=days; offset>=1; offset--)); do
    index=$(( (days - offset) % ${#mock_totals[@]} ))
    total="${mock_totals[$index]}"
    date_value="$(date -u -d "$offset days ago" +%F)"
    bedrock="$(awk -v total="$total" -v idx="$index" 'BEGIN {ratio = (idx == 7 ? 0.34 : 0.12); printf "%.2f", total * ratio}')"
    ec2="$(awk -v total="$total" 'BEGIN {printf "%.2f", total * 0.48}')"
    s3="$(awk -v total="$total" 'BEGIN {printf "%.2f", total * 0.18}')"
    cloudwatch="$(awk -v total="$total" 'BEGIN {printf "%.2f", total * 0.08}')"
    mock_objects+=("$(jq -cn               --arg date "$date_value"               --argjson total "$total"               --argjson bedrock "$bedrock"               --argjson ec2 "$ec2"               --argjson s3 "$s3"               --argjson cloudwatch "$cloudwatch"               '{
        date: $date,
        total: $total,
        bedrock: $bedrock,
        services: {
          "Amazon EC2": $ec2,
          "Amazon S3": $s3,
          "Amazon CloudWatch": $cloudwatch,
          "Amazon Bedrock": $bedrock
        }
      }')")
  done
  if [ "${#mock_objects[@]}" -gt 0 ]; then
    base_days="$(printf '%s
' "${mock_objects[@]}" | jq -s '.')"
  else
    base_days='[]'
  fi
fi

mapfile -t day_objects < <(jq -c '.[]' <<<"$base_days")
annotated_objects=()
previous_totals=()

for day_object in "${day_objects[@]}"; do
  total="$(jq -r '.total' <<<"$day_object")"
  recent_totals=("${previous_totals[@]}")
  if [ "${#recent_totals[@]}" -gt 7 ]; then
    recent_totals=("${recent_totals[@]: -7}")
  fi
  if [ "${#recent_totals[@]}" -gt 0 ]; then
    rolling_average="$(printf '%s
' "${recent_totals[@]}" | awk '{sum += $1; count += 1} END {if (count > 0) printf "%.2f", sum / count; else printf "0"}')"
  else
    rolling_average="0"
  fi
  anomalous="$(awk -v total="$total" -v average="$rolling_average" 'BEGIN {if (average > 0 && total > (average * 1.5)) print "true"; else print "false"}')"
  annotated_objects+=("$(jq -c --argjson rolling_average "$rolling_average" --argjson anomalous "$anomalous" '. + {rolling_average: $rolling_average, anomalous: $anomalous}' <<<"$day_object")")
  previous_totals+=("$total")
done

if [ "${#annotated_objects[@]}" -gt 0 ]; then
  daily_json="$(printf '%s
' "${annotated_objects[@]}" | jq -s '.')"
else
  daily_json='[]'
fi

jq -n           --arg source "$source_mode"           --arg region "${AWS_REGION:-mock-region}"           --arg start "$start_date"           --arg end "$end_date"           --argjson window_days "$days"           --argjson daily "$daily_json"           '{
    source: $source,
    generated_at: (now | todate),
    region: $region,
    window: {
      start: $start,
      end: $end,
      days: $window_days
    },
    anomaly_threshold: 1.5,
    days: $daily,
    summary: {
      total_spend: ([ $daily[]?.total ] | add // 0),
      anomalous_days: ([ $daily[]? | select(.anomalous) | {date, total, rolling_average, bedrock} ]),
      bedrock_total: ([ $daily[]?.bedrock ] | add // 0)
    }
  }' > cost-report.json

anomaly_count="$(jq '.summary.anomalous_days | length' cost-report.json)"
echo "Fetched $(jq '.days | length' cost-report.json) day(s) of cost data from $source_mode mode; anomalies=$anomaly_count"
