#!/usr/bin/env bash
set -euo pipefail

audit_file="${1:-docker-audit.json}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$audit_file" ]; then
  "$SCRIPT_DIR/audit.sh" > "$audit_file"
fi

printf '## docker-hygiene weekly digest

'
printf '| Category | Count | Details |
| --- | ---: | --- |
'
printf '| Dangling images | %s | %s |
'           "$(jq '.dangling_images.count' "$audit_file")"           "$(jq -r 'if .dangling_images.ids | length > 0 then (.dangling_images.ids[:5] | join(", ")) else "none" end' "$audit_file")"
printf '| Exited containers | %s | %s |
'           "$(jq '.exited_containers.count' "$audit_file")"           "$(jq -r 'if .exited_containers.names | length > 0 then (.exited_containers.names[:5] | join(", ")) else "none" end' "$audit_file")"
printf '| Unused volumes | %s | %s |
'           "$(jq '.unused_volumes.count' "$audit_file")"           "$(jq -r 'if .unused_volumes.names | length > 0 then (.unused_volumes.names[:5] | join(", ")) else "none" end' "$audit_file")"

printf '
### Disk usage

'
printf '| Type | Total | Active | Size | Reclaimable |
| --- | ---: | ---: | --- | --- |
'
disk_lines="$(jq -r '.disk_usage[]? | "| \(.type) | \(.total_count) | \(.active) | \(.size) | \(.reclaimable) |"' "$audit_file")"
if [ -n "$disk_lines" ]; then
  printf '%s
' "$disk_lines"
else
  printf '| _unknown_ | 0 | 0 | n/a | n/a |
'
fi

printf '
### Prune savings estimate

'
jq -r 'if (.disk_usage | length) > 0 then (.disk_usage | map("- \(.type): \(.reclaimable)") | join("
")) else "- No disk usage data available." end' "$audit_file"

printf '
### Recommended next steps

'
if [ "$(jq '.dangling_images.count + .exited_containers.count + .unused_volumes.count' "$audit_file")" -gt 0 ]; then
  echo '- Run `bash skills/docker-hygiene/scripts/prune.sh --dry-run` to preview the targeted cleanup set.'
  echo '- Only use `--force` after a human confirms none of the exited containers or volumes are needed for debugging or rollback.'
else
  echo '- No obvious cleanup targets were found. Re-run the audit after the next image build or CI cycle.'
fi
