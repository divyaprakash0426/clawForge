#!/usr/bin/env bash
set -euo pipefail

: "${MEMORY_PATH:?meeting-prep retrieve-notes: set MEMORY_PATH}"
if [ -d "$MEMORY_PATH" ]; then
  echo "meeting-prep retrieve-notes: MEMORY_PATH is a directory." >&2
  exit 1
fi
if [ ! -f "$MEMORY_PATH" ]; then
  echo "meeting-prep retrieve-notes: MEMORY_PATH not found: $MEMORY_PATH" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  printf '[]\n'
  exit 0
fi

MEMORY_PATH="$MEMORY_PATH" python3 - "$@" <<'PY'
import json
import os
import pathlib
import re
import sys

keywords = [word.lower() for word in sys.argv[1:] if word.strip()]
text = pathlib.Path(os.environ["MEMORY_PATH"]).read_text(encoding="utf-8")
sections = []
parts = re.split(r"(?m)^##\s+", text)
for part in parts:
    if not part.strip():
        continue
    heading, *rest = part.splitlines()
    body = "\n".join(rest).strip()
    haystack = f"{heading}\n{body}".lower()
    score = sum(haystack.count(keyword) for keyword in keywords)
    if score > 0:
        excerpt_lines = [line.strip() for line in body.splitlines() if line.strip()][:4]
        sections.append({"heading": heading.strip(), "excerpt": " ".join(excerpt_lines)[:360], "score": score})
sections.sort(key=lambda item: (-item["score"], item["heading"]))
print(json.dumps(sections[:3], indent=2))
PY
