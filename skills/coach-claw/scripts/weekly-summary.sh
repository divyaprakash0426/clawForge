#!/usr/bin/env bash
# Aggregate the last 7 days of sessions and print a weekly summary
set -euo pipefail

SKILL_DIR="${COACH_CLAW_DIR:-$HOME/.coach-claw}"
LOG_FILE="$SKILL_DIR/sessions.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No sessions logged yet. Run scripts/log-session.sh first."
  exit 0
fi

python3 - "$LOG_FILE" << 'PYEOF'
import json, sys, os
from datetime import date, timedelta

log_file = sys.argv[1]
today = date.today()
week_start = today - timedelta(days=6)

sessions = []
with open(log_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            entry_date = date.fromisoformat(entry["date"])
            if week_start <= entry_date <= today:
                sessions.append(entry)
        except (json.JSONDecodeError, KeyError, ValueError):
            pass

if not sessions:
    print(f"No sessions in the last 7 days ({week_start} → {today}).")
    sys.exit(0)

total_min = sum(s.get("duration_min", 0) for s in sessions)
total_h = total_min // 60
total_rem = total_min % 60
intensity_counts = {"low": 0, "medium": 0, "high": 0}
for s in sessions:
    intensity_counts[s.get("intensity", "medium")] = intensity_counts.get(s.get("intensity", "medium"), 0) + 1

avg_load = sum(s.get("load_score", 5) for s in sessions) / len(sessions)

# Parse win/loss from scores
wins, losses = 0, 0
for s in sessions:
    score = s.get("score", "")
    if score:
        games = score.split()
        w = sum(1 for g in games if "-" in g and int(g.split("-")[0]) > int(g.split("-")[1]))
        l = sum(1 for g in games if "-" in g and int(g.split("-")[0]) < int(g.split("-")[1]))
        wins += w; losses += l

print(f"\n🏸 coach-claw weekly brief  {week_start} → {today}")
print(f"Court time : {total_h} h {total_rem} min  ({len(sessions)} session{'s' if len(sessions) != 1 else ''})")
print(f"Intensity  : low {intensity_counts['low']} · medium {intensity_counts['medium']} · high {intensity_counts['high']}")
if wins + losses > 0:
    print(f"Win/loss   : {wins}–{losses}")
load_str = f"{avg_load:.1f} / 10"
if avg_load >= 8:
    load_str += "  ⚠️  consider active-recovery day tomorrow"
print(f"Load score : {load_str}")
PYEOF

# Optional Telegram push
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  SUMMARY=$(python3 - "$LOG_FILE" 2>/dev/null << 'PYEOF'
import json, sys
from datetime import date, timedelta
log_file = sys.argv[1]
today = date.today()
week_start = today - timedelta(days=6)
sessions = []
with open(log_file) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            entry = json.loads(line)
            if date.fromisoformat(entry["date"]) >= week_start:
                sessions.append(entry)
        except Exception:
            pass
total_min = sum(s.get("duration_min", 0) for s in sessions)
avg_load = (sum(s.get("load_score", 5) for s in sessions) / len(sessions)) if sessions else 0
print(f"🏸 Weekly: {len(sessions)} sessions · {total_min//60}h{total_min%60}m · load {avg_load:.1f}/10")
PYEOF
  )
  curl -s -o /dev/null -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${SUMMARY}" || true
fi
