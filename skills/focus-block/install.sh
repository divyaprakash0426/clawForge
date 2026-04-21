#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in bash date python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "focus-block: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

journal_path="${JOURNAL_PATH:-$HOME/notes/focus-log.md}"
if [ -d "$journal_path" ]; then
  echo "focus-block: JOURNAL_PATH resolves to a directory: $journal_path" >&2
  exit 1
fi

echo "focus-block: ready. JOURNAL_PATH=$journal_path"
