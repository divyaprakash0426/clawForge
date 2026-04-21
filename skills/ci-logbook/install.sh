#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "ci-logbook requires python3." >&2
  exit 1
fi

echo "ci-logbook dependencies look available."
