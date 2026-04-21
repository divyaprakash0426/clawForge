#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "dep-hygiene requires python3." >&2
  exit 1
fi

echo "dep-hygiene dependencies look available."
