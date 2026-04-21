#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in git gh jq python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "weekly-brief: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

if [ -n "${REPO_LIST:-}" ]; then
  echo "weekly-brief: REPO_LIST configured."
else
  echo "weekly-brief: REPO_LIST is unset; the brief will be empty until you provide repo paths." >&2
fi

if [ -n "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  GH_TOKEN="$GITHUB_TOKEN" gh auth status >/dev/null 2>&1 || echo "weekly-brief: gh auth status did not confirm credentials; PR digest may fail." >&2
fi
