#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-}"
OUTPUT_PATH="${2:-}"

if [ "${MOCK_MODE:-0}" = "1" ]; then
  cat <<'EOF'
{"chunk_id":"mock-doc-001","source_file":"mock/agentic-ai.md","content":"Agentic AI systems coordinate tools, memory, and planning loops across multiple steps. This mock chunk represents a 500-word slice from a markdown source used during offline testing."}
{"chunk_id":"mock-doc-002","source_file":"mock/model-context-protocol.md","content":"Model Context Protocol enables structured tool calling and context handoff across local and remote runtimes. This mock chunk allows index.sh and query.sh to run without network access."}
EOF
  exit 0
fi

if [ -z "$SOURCE_DIR" ]; then
  echo "bedrock-rag chunk: usage: chunk.sh SOURCE_DIR [OUTPUT_PATH]" >&2
  exit 1
fi
if [ ! -d "$SOURCE_DIR" ]; then
  echo "bedrock-rag chunk: SOURCE_DIR not found: $SOURCE_DIR" >&2
  exit 1
fi

chunk_output="$OUTPUT_PATH"
if [ -n "$chunk_output" ]; then
  mkdir -p "$(dirname "$chunk_output")"
fi

python3 - "$SOURCE_DIR" <<'PY' > "${chunk_output:-/dev/stdout}"
import json
import pathlib
import re
import sys

source_dir = pathlib.Path(sys.argv[1])
files = sorted(source_dir.rglob("*.md"))
if not files:
    raise SystemExit("bedrock-rag chunk: no markdown files found.")


def slug(path: pathlib.Path) -> str:
    return re.sub(r"[^a-zA-Z0-9._-]+", "-", path.as_posix()).strip("-")


for file_path in files:
    words = file_path.read_text(encoding="utf-8").split()
    if not words:
        continue
    for idx, start in enumerate(range(0, len(words), 500), start=1):
        content = " ".join(words[start : start + 500]).strip()
        if not content:
            continue
        chunk = {
            "chunk_id": f"{slug(file_path.relative_to(source_dir))}-{idx:04d}",
            "source_file": str(file_path.relative_to(source_dir)),
            "content": content,
        }
        print(json.dumps(chunk, ensure_ascii=False))
PY
