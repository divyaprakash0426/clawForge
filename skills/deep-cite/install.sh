#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in curl jq python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "deep-cite: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

: "${SOURCE_DIR:?deep-cite: set SOURCE_DIR}"
: "${OUTPUT_DIR:?deep-cite: set OUTPUT_DIR}"

mkdir -p "$SOURCE_DIR" "$OUTPUT_DIR"
echo "deep-cite: directories ready. SOURCE_DIR=$SOURCE_DIR OUTPUT_DIR=$OUTPUT_DIR"
