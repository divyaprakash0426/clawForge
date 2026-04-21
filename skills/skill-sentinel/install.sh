#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "skill-sentinel requires python3." >&2
  exit 1
fi

echo "skill-sentinel dependencies look available."
