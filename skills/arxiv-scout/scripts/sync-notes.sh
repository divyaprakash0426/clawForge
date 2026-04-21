#!/usr/bin/env bash
set -euo pipefail

MEMORY_PATH="${MEMORY_PATH:?MEMORY_PATH is required}"

if [ -d "$MEMORY_PATH" ]; then
  echo "sync-notes: MEMORY_PATH is a directory." >&2
  exit 1
fi

mkdir -p "$(dirname "$MEMORY_PATH")"
touch "$MEMORY_PATH"

if [ ! -w "$MEMORY_PATH" ]; then
  echo "sync-notes: MEMORY_PATH is not writable." >&2
  exit 1
fi

json_input="$(cat)"
if [ -z "$json_input" ]; then
  echo "sync-notes: expected paper JSON on stdin." >&2
  exit 1
fi

JSON_INPUT="$json_input" python3 - "$MEMORY_PATH" <<'PY'
import json
import os
import pathlib
import re
import sys

memory_path = pathlib.Path(sys.argv[1])
papers = json.loads(os.environ["JSON_INPUT"])
existing = memory_path.read_text(encoding="utf-8") if memory_path.exists() else ""
new_count = 0
skipped_count = 0
appended_ids = []
blocks = []


def clean(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


for paper in papers:
    paper_id = clean(paper.get("id", ""))
    if not paper_id:
        skipped_count += 1
        continue
    heading = f"## [{paper_id}] "
    if heading in existing or re.search(rf"\b{re.escape(paper_id)}\b", existing):
        skipped_count += 1
        continue
    title = clean(paper.get("title", "Untitled paper"))
    authors = ", ".join(clean(author) for author in paper.get("authors", []) if clean(author)) or "Unknown"
    published = clean(paper.get("published", "")) or "Unknown"
    summary = clean(paper.get("summary", "")) or "No summary available."
    link = clean(paper.get("link", "")) or f"https://arxiv.org/abs/{paper_id}"
    block = "\n".join(
        [
            "",
            f"## [{paper_id}] {title}",
            f"**Authors**: {authors}  ",
            f"**Published**: {published}  ",
            f"**Summary**: {summary}  ",
            f"**Link**: {link}",
        ]
    )
    blocks.append(block)
    appended_ids.append(paper_id)
    new_count += 1
    existing += block

if blocks:
    with memory_path.open("a", encoding="utf-8") as handle:
        for block in blocks:
            handle.write(block)
            handle.write("\n")

print(
    json.dumps(
        {
            "fetched": len(papers),
            "new": new_count,
            "skipped": skipped_count,
            "appended_ids": appended_ids,
            "memory_path": str(memory_path),
        },
        indent=2,
    )
)
PY
