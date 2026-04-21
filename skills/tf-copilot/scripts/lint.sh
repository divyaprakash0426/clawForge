#!/usr/bin/env bash
set -euo pipefail

checkov_available=false
tfsec_available=false
any_tool=0
checkov_findings='[]'
tfsec_findings='[]'

if command -v checkov >/dev/null 2>&1; then
  checkov_available=true
  any_tool=1
  checkov -d . --output json --quiet --soft-fail > tf-findings-checkov.json 2>/dev/null || true
  if [ -s tf-findings-checkov.json ] && jq empty tf-findings-checkov.json >/dev/null 2>&1; then
    checkov_findings="$(jq -c '[.results.failed_checks[]? | {
      tool: "checkov",
      id: (.check_id // "checkov"),
      severity: ((.severity // "MEDIUM") | ascii_upcase | if . == "CRITICAL" then "HIGH" else . end),
      file: (.file_path // ""),
      resource: (.resource // ""),
      message: (.check_name // "checkov finding"),
      remediation: (.guideline // "")
    }]' tf-findings-checkov.json)"
  else
    echo "Warning: checkov did not emit valid JSON output." >&2
  fi
else
  echo "Warning: checkov not installed; skipping." >&2
fi

if command -v tfsec >/dev/null 2>&1; then
  tfsec_available=true
  any_tool=1
  tfsec . --format json --soft-fail > tf-findings-tfsec.json 2>/dev/null || true
  if [ -s tf-findings-tfsec.json ] && jq empty tf-findings-tfsec.json >/dev/null 2>&1; then
    tfsec_findings="$(jq -c '[.results[]? | {
      tool: "tfsec",
      id: (.rule_id // .long_id // "tfsec"),
      severity: ((.severity // "MEDIUM") | ascii_upcase | if . == "CRITICAL" then "HIGH" else . end),
      file: (.location.filename // ""),
      resource: (.resource // ""),
      message: (.description // .rule_description // "tfsec finding"),
      remediation: (.resolution // "")
    }]' tf-findings-tfsec.json)"
  else
    echo "Warning: tfsec did not emit valid JSON output." >&2
  fi
else
  echo "Warning: tfsec not installed; skipping." >&2
fi

if [ "$any_tool" -eq 0 ]; then
  echo "Warning: neither checkov nor tfsec is installed; skipping compliance gate."
  exit 0
fi

jq -n           --argjson checkov "$checkov_findings"           --argjson tfsec "$tfsec_findings"           --arg checkov_available "$checkov_available"           --arg tfsec_available "$tfsec_available"           '
  ($checkov + $tfsec) as $all
  | {
      findings: $all,
      summary: {
HIGH: ([ $all[]? | select((.severity // "UNKNOWN") == "HIGH") ] | length),
MEDIUM: ([ $all[]? | select((.severity // "UNKNOWN") == "MEDIUM") ] | length),
LOW: ([ $all[]? | select((.severity // "UNKNOWN") == "LOW") ] | length),
UNKNOWN: ([ $all[]? | select((.severity // "UNKNOWN") != "HIGH" and (.severity // "UNKNOWN") != "MEDIUM" and (.severity // "UNKNOWN") != "LOW") ] | length)
      },
      tools: [
{name: "checkov", available: ($checkov_available == "true"), output: "tf-findings-checkov.json"},
{name: "tfsec", available: ($tfsec_available == "true"), output: "tf-findings-tfsec.json"}
      ]
    }
  ' > tf-findings.json

high="$(jq '.summary.HIGH // 0' tf-findings.json)"
medium="$(jq '.summary.MEDIUM // 0' tf-findings.json)"
low="$(jq '.summary.LOW // 0' tf-findings.json)"
echo "HIGH=$high MEDIUM=$medium LOW=$low"
