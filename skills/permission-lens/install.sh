#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in python3 awk sed; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[ok] $bin"
  else
    echo "[missing] $bin"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "permission-lens requires python3, awk, and sed." >&2
  exit 1
fi
