#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in git jq; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[ok] $bin"
  else
    echo "[missing] $bin"
    missing=1
  fi
done

if command -v gitleaks >/dev/null 2>&1; then
  echo "[ok] gitleaks"
else
  echo "[warn] gitleaks not found; secret-guard will fall back to trufflehog or built-in regex scanning."
fi

if command -v trufflehog >/dev/null 2>&1; then
  echo "[ok] trufflehog"
else
  echo "[warn] trufflehog not found; built-in regex scanning remains available."
fi

if [ "$missing" -ne 0 ]; then
  echo "secret-guard requires git and jq." >&2
  exit 1
fi
