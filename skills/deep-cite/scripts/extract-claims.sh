#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_DIR:?deep-cite extract: set SOURCE_DIR}"
CLAIMS_PATH="${1:-${OUTPUT_DIR:-}/claims.json}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "deep-cite extract: SOURCE_DIR not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ -n "$CLAIMS_PATH" ]; then
  mkdir -p "$(dirname "$CLAIMS_PATH")"
fi

SOURCE_DIR="$SOURCE_DIR" python3 - <<'PY' > "${CLAIMS_PATH:-/dev/stdout}"
import html
import json
import os
import pathlib
import re

source_dir = pathlib.Path(os.environ["SOURCE_DIR"])
markers = ["found", "showed", "demonstrated", "reported", "study", "according to"]
claims = []

for file_path in sorted(source_dir.glob("*.html")):
    raw = file_path.read_text(encoding="utf-8")
    raw = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", raw)
    text = re.sub(r"(?s)<[^>]+>", "\n", raw)
    text = html.unescape(text)
    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    for line_number, line in enumerate(lines, start=1):
        if not line:
            continue
        sentences = re.split(r"(?<=[.!?])\s+", line)
        for sentence in sentences:
            compact = re.sub(r"\s+", " ", sentence).strip()
            lowered = compact.lower()
            if compact and any(marker in lowered for marker in markers):
                claims.append(
                    {
                        "source_file": file_path.name,
                        "claim_text": compact,
                        "line_number": line_number,
                    }
                )

print(json.dumps(claims, indent=2))
PY
