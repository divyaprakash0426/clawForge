#!/usr/bin/env bash
set -euo pipefail

target="${1:-.}"

if [ ! -e "$target" ]; then
  echo "Target path does not exist: $target" >&2
  exit 1
fi

for bin in git jq grep sed; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "secret-guard requires $bin." >&2
    exit 1
  fi
done

mask_value() {
  local value="${1//$'\n'/ }"
  if [ -z "$value" ]; then
    printf '***'
  elif [ "${#value}" -le 6 ]; then
    printf '%s***' "$value"
  else
    printf '%s***' "${value:0:6}"
  fi
}

findings=()
append_finding() {
  local tool="$1"
  local file="$2"
  local line="$3"
  local rule_id="$4"
  local severity="$5"
  local raw_value="$6"
  findings+=("$(jq -cn --arg tool "$tool" --arg file "$file" --argjson line "$line" --arg rule_id "$rule_id" --arg severity "$severity" --arg masked_value "$(mask_value "$raw_value")" '{tool: $tool, file: $file, line: $line, rule_id: $rule_id, severity: $severity, masked_value: $masked_value}')")
}

if command -v gitleaks >/dev/null 2>&1; then
  report_file="secret-findings-gitleaks.json"
  gitleaks detect --source "$target" --report-format json --report-path "$report_file" --redact --no-banner --exit-code 0 >/dev/null 2>&1 || true
  if [ -s "$report_file" ] && jq empty "$report_file" >/dev/null 2>&1; then
    jq '[.[]? | {
      tool: "gitleaks",
      file: (.File // .file // ""),
      line: (.StartLine // .startLine // 0),
      rule_id: (.RuleID // .ruleID // "gitleaks"),
      severity: (if ((.Tags // []) | map(ascii_upcase) | index("HIGH")) then "HIGH" elif ((.Tags // []) | map(ascii_upcase) | index("LOW")) then "LOW" else "MEDIUM" end),
      masked_value: ((.Secret // .Match // "redacted") | tostring | if . == "" then "***" else (.[0:6] + "***") end)
    }]' "$report_file" > secret-findings.json
    rm -f "$report_file"
    echo "Found $(jq 'length' secret-findings.json) findings in $target"
    exit 0
  fi
  rm -f "$report_file"
fi

if command -v trufflehog >/dev/null 2>&1; then
  trufflehog_output="$(trufflehog filesystem "$target" --json 2>/dev/null || true)"
  if [ -n "$trufflehog_output" ]; then
    printf '%s\n' "$trufflehog_output" | jq -s '[.[]? | {
      tool: "trufflehog",
      file: (.SourceMetadata.Data.Filesystem.file // .SourceMetadata.Data.Git.file // ""),
      line: (.SourceMetadata.Data.Filesystem.line // .SourceMetadata.Data.Git.line // 0),
      rule_id: (.DetectorName // .DetectorType // "trufflehog"),
      severity: "HIGH",
      masked_value: (((.Redacted // .Raw // .RawV2 // "redacted") | tostring) | if . == "" then "***" else (.[0:6] + "***") end)
    }]' > secret-findings.json
    echo "Found $(jq 'length' secret-findings.json) findings in $target"
    exit 0
  fi
fi

base_dir="$target"
relative_files=()
secret_assignment_regex="(API[_-]?KEY|TOKEN|SECRET|PASSWORD|ACCESS_KEY|PRIVATE_KEY)[A-Za-z0-9_[:space:]-]*[:=][[:space:]]*['\\\"]?([^'\\\"[:space:]#]+)"
if [ -f "$target" ]; then
  base_dir="$(dirname -- "$target")"
  relative_files=("$(basename -- "$target")")
elif git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t relative_files < <(git -C "$target" ls-files -- 'SKILL.md' '*.sh' '*.md' '*.json' '.env' '.env.*')
else
  mapfile -t relative_files < <(find "$target" -type f \( -name 'SKILL.md' -o -name '*.sh' -o -name '*.md' -o -name '*.json' -o -name '.env' -o -name '.env.*' \) -printf '%P\n')
fi

for relative_path in "${relative_files[@]}"; do
  [ -n "$relative_path" ] || continue
  file_path="$base_dir/$relative_path"
  [ -f "$file_path" ] || continue
  grep -Iq . "$file_path" || continue
  line_number=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_number=$((line_number + 1))
    if [[ $line =~ (AKIA[0-9A-Z]{16}) ]]; then
      append_finding "builtin" "$file_path" "$line_number" "aws-access-key" "HIGH" "${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ (ASIA[0-9A-Z]{16}) ]]; then
      append_finding "builtin" "$file_path" "$line_number" "aws-temporary-key" "HIGH" "${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ -----BEGIN[[:space:]][A-Z[:space:]]*PRIVATE[[:space:]]KEY----- ]]; then
      append_finding "builtin" "$file_path" "$line_number" "private-key-header" "HIGH" "-----BEGIN PRIVATE KEY-----"
    fi
    if [[ $line =~ $secret_assignment_regex ]]; then
      append_finding "builtin" "$file_path" "$line_number" "generic-secret-assignment" "MEDIUM" "${BASH_REMATCH[2]}"
    fi
  done < "$file_path"
done

if [ "${#findings[@]}" -gt 0 ]; then
  printf '%s\n' "${findings[@]}" | jq -s '.' > secret-findings.json
else
  printf '[]\n' > secret-findings.json
fi

echo "Found $(jq 'length' secret-findings.json) findings in $target"
