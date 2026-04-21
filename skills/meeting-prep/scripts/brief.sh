#!/usr/bin/env bash
set -euo pipefail

event_json_path="${1:-}"
notes_json_path="${2:-}"
if [ -z "$event_json_path" ] || [ -z "$notes_json_path" ]; then
  echo "usage: brief.sh event.json notes.json" >&2
  exit 1
fi

python3 - "$event_json_path" "$notes_json_path" <<'PY'
import json
import pathlib
import sys

event = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
notes = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))

attendees = ", ".join(event.get("attendees", [])) or "No attendees listed"
agenda = event.get("description", "").strip() or "No agenda provided"

lines = [
    f"# Meeting Brief: {event.get('title', 'Upcoming Meeting')}",
    f"**Time**: {event.get('start_time', 'Unknown')}  ",
    f"**Attendees**: {attendees}  ",
    "",
    "## Agenda",
    agenda,
    "",
    "## Related Notes from Memory",
]

if notes:
    for note in notes:
        lines.append(f"> From MEMORY.md § \"{note['heading']}\"  ")
        lines.append(f"> {note['excerpt']}")
        lines.append(">")
else:
    lines.append("> No matching notes were found in MEMORY.md.")

lines.extend(
    [
        "",
        "## Talking Points",
        "- TBD — review backlog, decisions, or action items before the meeting",
        "- TBD — confirm the most recent status from related notes",
    ]
)

print("\n".join(lines).rstrip() + "\n")
PY
