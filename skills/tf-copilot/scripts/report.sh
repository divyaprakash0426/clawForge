#!/usr/bin/env bash
set -euo pipefail

plan_file="${1:-tf-plan.json}"
findings_file="${2:-tf-findings.json}"

printf '## tf-copilot report

'

if [ -f "$plan_file" ]; then
  add_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("create"))] | length' "$plan_file")"
  change_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("update"))] | length' "$plan_file")"
  destroy_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("delete"))] | length' "$plan_file")"

  printf '| Action | Count |
| --- | ---: |
'
  printf '| Add | %s |
' "$add_count"
  printf '| Change | %s |
' "$change_count"
  printf '| Destroy | %s |
' "$destroy_count"

  printf '
### Resource type breakdown

'
  printf '| Resource type | Count |
| --- | ---: |
'
  type_breakdown="$(jq -r '[.resource_changes[]? | (.type // "unknown")] | group_by(.) | map({type: .[0], count: length}) | .[]? | "| `\(.type)` | \(.count) |"' "$plan_file")"
  if [ -n "$type_breakdown" ]; then
    printf '%s
' "$type_breakdown"
  else
    printf '| _none_ | 0 |
'
  fi

  printf '
### Provider constraints

'
  printf '| Provider | Constraint |
| --- | --- |
'
  provider_lines="$(jq -r '[.configuration.provider_config? | to_entries[]? | {provider: (.value.full_name // .value.name // .key), constraint: (.value.version_constraint // "unspecified")}] | unique_by(.provider + "|" + .constraint) | .[]? | "| `\(.provider)` | `\(.constraint)` |"' "$plan_file")"
  if [ -n "$provider_lines" ]; then
    printf '%s
' "$provider_lines"
  else
    printf '| _unknown_ | `unspecified` |
'
  fi

  if [ "$destroy_count" -gt 0 ]; then
    printf '
> WARNING: %s resource(s) scheduled for destroy.
' "$destroy_count"
    jq -r '.resource_changes[]? | select((.change.actions // []) | index("delete")) | "- `\(.address)`"' "$plan_file"
  fi
else
  printf '_No plan JSON available. Run `scripts/plan.sh` first._
'
fi

printf '
### Compliance summary

'
printf '| Severity | Count |
| --- | ---: |
'
if [ -f "$findings_file" ]; then
  printf '| HIGH | %s |
' "$(jq '.summary.HIGH // 0' "$findings_file")"
  printf '| MEDIUM | %s |
' "$(jq '.summary.MEDIUM // 0' "$findings_file")"
  printf '| LOW | %s |
' "$(jq '.summary.LOW // 0' "$findings_file")"

  top_findings="$(jq -r '.findings[:5][]? | "- [\(.severity)] `\(.id)` in `\(.file)` — \(.message)"' "$findings_file")"
  if [ -n "$top_findings" ]; then
    printf '
### Top findings

%s
' "$top_findings"
  fi
else
  printf '| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
'
  printf '
_No compliance findings file found. Run `scripts/lint.sh` to generate one._
'
fi

printf '
### Recommended fixes

'
destroy_count_report=0
if [ -f "$plan_file" ]; then
  destroy_count_report="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("delete"))] | length' "$plan_file")"
fi
high_count=0
medium_count=0
if [ -f "$findings_file" ]; then
  high_count="$(jq '.summary.HIGH // 0' "$findings_file")"
  medium_count="$(jq '.summary.MEDIUM // 0' "$findings_file")"
fi

if [ "$destroy_count_report" -gt 0 ]; then
  echo '- Review each destroy target and require explicit operator approval before merging or applying any follow-up plan.'
fi
if [ "$high_count" -gt 0 ]; then
  echo '- Triage HIGH findings first; update Terraform code or module inputs before re-running the plan.'
fi
if [ "$medium_count" -gt 0 ]; then
  echo '- Address MEDIUM findings next or document a compliance waiver with justification.'
fi
if [ "$destroy_count_report" -eq 0 ] && [ "$high_count" -eq 0 ] && [ "$medium_count" -eq 0 ]; then
  echo '- No urgent fixes detected. Re-run `plan.sh` and `lint.sh` after the next Terraform change.'
fi
