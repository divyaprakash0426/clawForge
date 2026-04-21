#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in python3 jq grep; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "meeting-prep: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

: "${MEMORY_PATH:?meeting-prep: set MEMORY_PATH}"
if [ -d "$MEMORY_PATH" ]; then
  echo "meeting-prep: MEMORY_PATH is a directory: $MEMORY_PATH" >&2
  exit 1
fi

if [ -n "${CALENDAR_ICS:-}" ] && [ ! -f "$CALENDAR_ICS" ]; then
  echo "meeting-prep: CALENDAR_ICS does not exist: $CALENDAR_ICS" >&2
  exit 1
fi

if [ -z "${CALENDAR_ICS:-}" ] && ! command -v calcurse >/dev/null 2>&1 && [ "${MOCK_MODE:-0}" != "1" ]; then
  echo "meeting-prep: provide CALENDAR_ICS, calcurse, or MOCK_MODE=1." >&2
  exit 1
fi
