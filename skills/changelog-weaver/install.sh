#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "changelog-weaver requires git." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "changelog-weaver requires python3." >&2
  exit 1
fi

echo "changelog-weaver dependencies look available."
