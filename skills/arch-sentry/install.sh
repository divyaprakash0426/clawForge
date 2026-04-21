#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "arch-sentry expects pacman to be available." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "arch-sentry expects jq to be installed for report formatting." >&2
  exit 1
fi

echo "arch-sentry dependencies look available."
