#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in aws jq curl; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[ok] $bin"
  else
    echo "[missing] $bin"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "aws-cost-watcher requires aws, jq, and curl." >&2
  exit 1
fi

if [ -n "${AWS_PROFILE:-}${AWS_ACCESS_KEY_ID:-}${AWS_SESSION_TOKEN:-}" ]; then
  if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "[ok] aws sts get-caller-identity"
  else
    echo "[warn] AWS credentials appear to be configured but STS validation failed." >&2
  fi
else
  echo "[warn] AWS credentials are not configured yet; fetch.sh will require them."
fi
