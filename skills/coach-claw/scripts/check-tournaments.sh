#!/usr/bin/env bash
# Display upcoming tournaments with days-until and prep-phase labels
set -euo pipefail

SKILL_DIR="${COACH_CLAW_DIR:-$HOME/.coach-claw}"
TOURNAMENTS_FILE="$SKILL_DIR/tournaments.json"

if [[ ! -f "$TOURNAMENTS_FILE" ]]; then
  echo "No tournaments file found at $TOURNAMENTS_FILE."
  echo "Run install.sh to create a seed file, then edit it with your fixtures."
  exit 0
fi

python3 - "$TOURNAMENTS_FILE" << 'PYEOF'
import json, sys
from datetime import date

tournaments_file = sys.argv[1]
today = date.today()

with open(tournaments_file) as f:
    events = json.load(f)

upcoming = []
for ev in events:
    try:
        ev_date = date.fromisoformat(ev["date"])
        days_until = (ev_date - today).days
        if days_until >= 0:
            upcoming.append((days_until, ev_date, ev))
    except (KeyError, ValueError):
        pass

upcoming.sort()

if not upcoming:
    print("No upcoming tournaments found. Edit ~/.coach-claw/tournaments.json to add events.")
    sys.exit(0)

print("\n🏸 coach-claw — upcoming tournaments\n")
for days_until, ev_date, ev in upcoming:
    name     = ev.get("name", "Unknown")
    location = ev.get("location", "—")
    level    = ev.get("level", "—")

    if days_until > 60:
        phase = "base"
    elif days_until > 30:
        phase = "build"
    elif days_until > 14:
        phase = "peak"
    elif days_until > 7:
        phase = "taper"
    elif days_until > 0:
        phase = "race week"
    else:
        phase = "today!"

    print(f"  {ev_date}  [{days_until:3d} days]  {name}")
    print(f"             📍 {location}  |  level: {level}  |  prep phase: {phase}")
    print()
PYEOF
