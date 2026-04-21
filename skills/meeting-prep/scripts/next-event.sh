#!/usr/bin/env bash
set -euo pipefail

if [ "${MOCK_MODE:-0}" = "1" ]; then
  cat <<'EOF'
{
  "title": "Sprint Planning",
  "start_time": "2024-06-15 10:00",
  "attendees": ["alice@example.com", "bob@example.com"],
  "description": "Review backlog priority, confirm acceptance criteria, and assign follow-up owners."
}
EOF
  exit 0
fi

if [ -n "${CALENDAR_ICS:-}" ]; then
  CALENDAR_ICS="$CALENDAR_ICS" python3 - <<'PY'
import datetime as dt
import json
import os
import pathlib

ics_path = pathlib.Path(os.environ["CALENDAR_ICS"])
if not ics_path.exists():
    raise SystemExit(f"meeting-prep next-event: calendar file not found: {ics_path}")

raw_lines = ics_path.read_text(encoding="utf-8").splitlines()
lines = []
for line in raw_lines:
    if line.startswith((" ", "\t")) and lines:
        lines[-1] += line[1:]
    else:
        lines.append(line)

events = []
current = None
for line in lines:
    if line == "BEGIN:VEVENT":
        current = {}
        continue
    if line == "END:VEVENT" and current is not None:
        events.append(current)
        current = None
        continue
    if current is None or ":" not in line:
        continue
    key, value = line.split(":", 1)
    current.setdefault(key, []).append(value)

now = dt.datetime.now(dt.timezone.utc)
cutoff = now + dt.timedelta(hours=24)


def parse_dt(raw: str):
    raw = raw.strip()
    for fmt in ("%Y%m%dT%H%M%SZ", "%Y%m%dT%H%M%S", "%Y%m%d"):
        try:
            parsed = dt.datetime.strptime(raw, fmt)
            if fmt.endswith("Z"):
                return parsed.replace(tzinfo=dt.timezone.utc)
            if fmt == "%Y%m%d":
                return parsed.replace(tzinfo=dt.timezone.utc)
            return parsed.astimezone(dt.timezone.utc) if parsed.tzinfo else parsed.replace(tzinfo=dt.timezone.utc)
        except ValueError:
            continue
    return None


candidates = []
for event in events:
    start_key = next((key for key in event if key.startswith("DTSTART")), None)
    if not start_key:
        continue
    start_raw = event[start_key][0]
    start_dt = parse_dt(start_raw)
    if not start_dt or start_dt < now or start_dt > cutoff:
        continue
    attendees = []
    for key, values in event.items():
        if key.startswith("ATTENDEE"):
            for value in values:
                attendees.append(value.replace("MAILTO:", "").replace("mailto:", ""))
    description = "\n".join(event.get("DESCRIPTION", [""])).replace("\\n", "\n").strip()
    summary = " ".join(event.get("SUMMARY", ["Untitled event"])).strip()
    candidates.append(
        {
            "title": summary,
            "start_time": start_dt.astimezone().strftime("%Y-%m-%d %H:%M"),
            "attendees": attendees,
            "description": description,
            "_start": start_dt,
        }
    )

if not candidates:
    print("null")
else:
    candidates.sort(key=lambda item: item["_start"])
    event = candidates[0]
    event.pop("_start", None)
    print(json.dumps(event, indent=2))
PY
  exit 0
fi

if command -v calcurse >/dev/null 2>&1; then
  raw="$(calcurse -n 2>/dev/null || true)"
  if [ -n "$raw" ]; then
    RAW_EVENT="$raw" python3 - <<'PY'
import json
import os
import re

raw = os.environ["RAW_EVENT"]
lines = [line.strip() for line in raw.splitlines() if line.strip()]
title = lines[-1] if lines else "Upcoming calcurse event"
time_match = re.search(r"(\d{1,2}:\d{2})", raw)
start_time = time_match.group(1) if time_match else "Unknown"
print(json.dumps({"title": title, "start_time": start_time, "attendees": [], "description": raw}, indent=2))
PY
    exit 0
  fi
fi

printf 'null\n'
