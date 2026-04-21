#!/usr/bin/env bash
set -euo pipefail

JOURNAL_PATH="${JOURNAL_PATH:-$HOME/notes/focus-log.md}"

if [ ! -f "$JOURNAL_PATH" ]; then
  echo "focus-block end: journal not found: $JOURNAL_PATH" >&2
  exit 1
fi

update_json="$(JOURNAL_PATH="$JOURNAL_PATH" python3 - <<'PY'
import datetime as dt
import json
import os
import pathlib
import re

journal_path = pathlib.Path(os.environ["JOURNAL_PATH"])
text = journal_path.read_text(encoding="utf-8")
match = list(re.finditer(r'(?ms)^## Focus Session (?P<id>[^\n]+)\n- task: (?P<task>.*?)\n- start: (?P<start>.*?)\n- end: (?P<end>.*?)\n- duration_minutes: (?P<duration>.*?)\n- status: (?P<status>.*?)\n- dnd_disabled: (?P<dnd>.*?)\n(?=^## Focus Session |\Z)', text))
open_match = None
for candidate in reversed(match):
    if candidate.group("status").strip() == "open":
        open_match = candidate
        break
if open_match is None:
    raise SystemExit("focus-block end: no open session found.")

start_time = dt.datetime.fromisoformat(open_match.group("start").strip())
end_time = dt.datetime.now(start_time.tzinfo)
duration = max(1, round((end_time - start_time).total_seconds() / 60))
replacement = "\n".join(
    [
        f"## Focus Session {open_match.group('id').strip()}",
        f"- task: {open_match.group('task').strip()}",
        f"- start: {open_match.group('start').strip()}",
        f"- end: {end_time.isoformat(timespec='seconds')}",
        f"- duration_minutes: {duration}",
        "- status: complete",
        "",
    ]
)
new_text = text[:open_match.start()] + replacement + text[open_match.end():]
journal_path.write_text(new_text, encoding="utf-8")

completed_today = len(re.findall(rf'^## Focus Session {dt.date.today().strftime("%Y%m%d")}-', new_text, re.MULTILINE))
print(
    json.dumps(
        {
            "session_id": open_match.group("id").strip(),
            "task": open_match.group("task").strip(),
            "end_time": end_time.isoformat(timespec="seconds"),
            "duration_minutes": duration,
            "dnd_disabled": open_match.group("dnd").strip(),
            "completed_today": completed_today,
        }
    )
)
PY
)"

dnd_disabled="$(printf '%s' "$update_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["dnd_disabled"])')"
if [ "$dnd_disabled" = "true" ] && command -v gsettings >/dev/null 2>&1; then
  if ! gsettings set org.gnome.desktop.notifications show-banners true 2>/dev/null; then
    echo "focus-block end: could not restore GNOME notifications." >&2
  fi
fi

UPDATE_JSON="$update_json" python3 - <<'PY'
import json
import os
info = json.loads(os.environ["UPDATE_JSON"])
print(f"Completed focus session {info['session_id']}")
print(f"Task: {info['task']}")
print(f"Duration: {info['duration_minutes']} minutes")
if info["completed_today"] % 4 == 0:
    print("Suggestion: you've completed 4 Pomodoros today — take a 20-minute break.")
PY
