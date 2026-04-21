#!/usr/bin/env bash
set -euo pipefail

MOCK_MODE="${MOCK_MODE:-0}"

if [ "$MOCK_MODE" = "1" ]; then
  cat <<'EOF'
[
  {
    "id": "2406.00001",
    "title": "Agentic AI Planning with Model Context Protocol",
    "authors": ["Alice Example", "Bob Sample"],
    "published": "2024-06-01",
    "summary": "We introduce a planning framework for agentic AI systems using the Model Context Protocol to coordinate tool calls across distributed agents.",
    "link": "https://arxiv.org/abs/2406.00001"
  },
  {
    "id": "2406.00002",
    "title": "MCP-Bench: Evaluating Multi-Agent Tool Use",
    "authors": ["Carol Test"],
    "published": "2024-06-02",
    "summary": "MCP-Bench is a benchmark suite for measuring the reliability of MCP-driven multi-agent workflows on real-world tasks.",
    "link": "https://arxiv.org/abs/2406.00002"
  }
]
EOF
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "arxiv-scout fetch: curl is required." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "arxiv-scout fetch: python3 is required for XML parsing." >&2
  exit 1
fi

QUERY="ti:agentic+OR+ti:MCP+OR+abs:model-context-protocol+OR+abs:agentic-AI"
URL="https://export.arxiv.org/api/query?search_query=${QUERY}&max_results=20&sortBy=submittedDate&sortOrder=descending"

response="$(curl --silent --show-error --max-time 30 --write-out $'\n%{http_code}' "$URL")"
http_code="${response##*$'\n'}"
xml="${response%$'\n'*}"

if [ "$http_code" != "200" ]; then
  echo "arxiv-scout fetch: arXiv API returned HTTP $http_code." >&2
  exit 1
fi

if [ -z "$xml" ]; then
  echo "arxiv-scout fetch: empty response from arXiv API." >&2
  exit 1
fi

ARXIV_XML="$xml" python3 - <<'PY'
import json
import os
import re
import xml.etree.ElementTree as ET

xml = os.environ["ARXIV_XML"]
root = ET.fromstring(xml)
ns = {"atom": "http://www.w3.org/2005/Atom"}


def clean(value: str, limit: int | None = None) -> str:
    value = re.sub(r"\s+", " ", value or "").strip()
    if limit and len(value) > limit:
        return value[: limit - 3].rstrip() + "..."
    return value


results = []
for entry in root.findall("atom:entry", ns):
    raw_id = entry.findtext("atom:id", default="", namespaces=ns).strip()
    arxiv_id = raw_id.split("/abs/")[-1] if "/abs/" in raw_id else raw_id
    authors = [clean(node.text or "") for node in entry.findall("atom:author/atom:name", ns)]
    results.append(
        {
            "id": arxiv_id,
            "title": clean(entry.findtext("atom:title", default="", namespaces=ns)),
            "authors": authors,
            "published": (entry.findtext("atom:published", default="", namespaces=ns) or "")[:10],
            "summary": clean(entry.findtext("atom:summary", default="", namespaces=ns), limit=320),
            "link": raw_id or f"https://arxiv.org/abs/{arxiv_id}",
        }
    )

print(json.dumps(results, indent=2))
PY
