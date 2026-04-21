#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in curl jq python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "arxiv-scout: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

if [ -z "${MEMORY_PATH:-}" ]; then
  echo "arxiv-scout: MEMORY_PATH is not set. Set it to a writable markdown file path." >&2
  exit 1
fi

if [ -d "$MEMORY_PATH" ]; then
  echo "arxiv-scout: MEMORY_PATH ($MEMORY_PATH) is a directory, not a file." >&2
  exit 1
fi

echo "arxiv-scout: all dependencies present. MEMORY_PATH=$MEMORY_PATH"
