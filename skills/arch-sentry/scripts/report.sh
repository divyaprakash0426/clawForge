#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "arch-sentry report formatting requires jq." >&2
  exit 1
fi

audit_json="$("$SCRIPT_DIR/audit.sh")"

jq -r '
  "## arch-sentry report",
  "",
  "- pacman cache size: \(.cache_size)",
  "- orphan packages: \(.orphan_count)",
  "- pacnew / pacsave files: \(.pacnew_count)",
  "",
  "### Recommended next actions",
  (
    if .orphan_count > 0 then
      "- Review orphan packages before removal."
    else
      "- No orphan packages detected."
    end
  ),
  (
    if .pacnew_count > 0 then
      "- Review pacnew and pacsave files before replacing active configs."
    else
      "- No pacnew or pacsave drift detected."
    end
  )
' <<<"$audit_json"
