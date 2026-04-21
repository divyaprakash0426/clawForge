#!/usr/bin/env bash
set -euo pipefail

report_file="${1:-secret-findings.json}"

if [ ! -f "$report_file" ]; then
  echo "Report file not found: $report_file" >&2
  exit 1
fi

printf '## secret-guard report

'
printf '| Severity | Count |
| --- | ---: |
'
printf '| HIGH | %s |
' "$(jq '[.[]? | select(.severity == "HIGH")] | length' "$report_file")"
printf '| MEDIUM | %s |
' "$(jq '[.[]? | select(.severity == "MEDIUM")] | length' "$report_file")"
printf '| LOW | %s |
' "$(jq '[.[]? | select(.severity == "LOW")] | length' "$report_file")"

printf '
### Findings

'
printf '| File | Line | Rule | Severity | Masked value |
| --- | ---: | --- | --- | --- |
'
finding_lines="$(jq -r '.[]? | "| `\(.file)` | \(.line) | `\(.rule_id)` | \(.severity) | `\(.masked_value)` |"' "$report_file")"
if [ -n "$finding_lines" ]; then
  printf '%s
' "$finding_lines"
else
  printf '| _none_ | 0 | clean | info | `n/a` |
'
fi

printf '
### Remediation guidance

'
echo '- Rotate or revoke any credential that appears to be real before making repository changes.'
echo '- Remove leaked material from Git history with `git filter-repo` or the legacy `git filter-branch` flow if `filter-repo` is unavailable.'
echo '- Add `.env`, `*.pem`, generated secrets, and local sample credentials to `.gitignore`.'
echo '- Re-run `scan.sh` until the report only shows expected test fixtures or zero findings.'
