#!/usr/bin/env bash
set -euo pipefail

if [ -z "${LOGBOOK_PATH:-}" ] || [ ! -f "$LOGBOOK_PATH" ]; then
  echo "weekly-brief logbook-digest: LOGBOOK_PATH is unset or missing; skipping logbook section." >&2
  printf '[]\n'
  exit 0
fi

LOGBOOK_PATH="$LOGBOOK_PATH" python3 - <<'PY'
import datetime as dt
import json
import os
import pathlib
import re

logbook = pathlib.Path(os.environ["LOGBOOK_PATH"])
text = logbook.read_text(encoding="utf-8")
sections = re.split(r"(?m)^##\s+", text)
cutoff = dt.date.today() - dt.timedelta(days=6)
results = []

for section in sections:
    if not section.strip():
        continue
    heading, *rest = section.splitlines()
    heading = heading.strip()
    try:
        section_date = dt.date.fromisoformat(heading)
    except ValueError:
        continue
    if section_date < cutoff:
        continue
    snippet = "\n".join(line.rstrip() for line in rest if line.strip())
    results.append({"date": heading, "snippet": snippet[:600]})

print(json.dumps(results, indent=2))
PY
