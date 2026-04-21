#!/usr/bin/env bash
set -euo pipefail

missing=0
check_bin() {
  local bin="$1"
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[ok] $bin"
  else
    echo "[missing] $bin"
    missing=1
  fi
}

check_bin terraform
check_bin checkov
check_bin tfsec
check_bin aws
check_bin jq

if [ "$missing" -ne 0 ]; then
  echo "tf-copilot is missing required tooling. Install the missing binaries above and re-run." >&2
  exit 1
fi

echo "tf-copilot dependencies look available."
