#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="${1:-}"

: "${SOURCE_DIR:?deep-cite run: set SOURCE_DIR}"
: "${OUTPUT_DIR:?deep-cite run: set OUTPUT_DIR}"

if [ -z "$SOURCES_FILE" ] || [ ! -f "$SOURCES_FILE" ]; then
  echo "usage: run.sh sources.txt" >&2
  exit 1
fi

mkdir -p "$SOURCE_DIR" "$OUTPUT_DIR"

"$SCRIPT_DIR/fetch-sources.sh" "$SOURCES_FILE" >/dev/null
claims_path="$OUTPUT_DIR/claims.json"
"$SCRIPT_DIR/extract-claims.sh" "$claims_path" >/dev/null
echo "deep-cite: review candidate claims at $claims_path before publishing externally." >&2
"$SCRIPT_DIR/cite.sh" "$claims_path"
