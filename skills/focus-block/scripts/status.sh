#!/usr/bin/env bash
set -euo pipefail

JOURNAL_PATH="${JOURNAL_PATH:-$HOME/notes/focus-log.md}"

if [ ! -f "$JOURNAL_PATH" ]; then
  echo "focus-block status: no journal found at $JOURNAL_PATH" >&2
  exit 0
fi

JOURNAL_PATH="$JOURNAL_PATH" python3 - <<'PY'
import datetime as dt
import os
import pathlib
import re

journal = pathlib.Path(os.environ["JOURNAL_PATH"]).read_text(encoding="utf-8")
today = dt.date.today().strftime("%Y%m%d")
pattern = re.compile(r'(?ms)^## Focus Session (?P<id>' + today + r'[^\n]*)\n- task: (?P<task>.*?)\n- start: (?P<start>.*?)\n- end: (?P<end>.*?)\n- duration_minutes: (?P<duration>.*?)\n- status: (?P<status>.*?)(?:\n- dnd_disabled: (?P<dnd>.*?))?\n(?=^## Focus Session |\Z)')
matches = list(pattern.finditer(journal))
print(f"# Focus Status for {dt.date.today().isoformat()}\n")
if not matches:
    print("- No sessions recorded today.")
for match in matches:
    print(
        f"- {match.group('id').strip()} | started {match.group('start').strip()} | ended {match.group('end').strip()} | duration {match.group('duration').strip()} | task {match.group('task').strip()} | status {match.group('status').strip()}"
    )
PY
