#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -lt 1 ]; then
  echo "usage: run.sh SOURCE_DIR [--query \"question\"]" >&2
  exit 1
fi

SOURCE_DIR="$1"
shift

query=""
if [ "${1:-}" = "--query" ]; then
  shift
  query="${*:-}"
fi

chunk_file="${CHUNK_OUTPUT_PATH:-${SOURCE_DIR%/}/.bedrock-rag.chunks.jsonl}"
cleanup_chunk=0
if [ -z "${CHUNK_OUTPUT_PATH:-}" ]; then
  cleanup_chunk=1
fi

trap '[ "$cleanup_chunk" -eq 1 ] && rm -f "$chunk_file"' EXIT

"$SCRIPT_DIR/chunk.sh" "$SOURCE_DIR" > "$chunk_file"
result="$("$SCRIPT_DIR/index.sh" "$chunk_file")"
echo "$result"

if [ -n "$query" ]; then
  echo
  "$SCRIPT_DIR/query.sh" "$query"
fi
