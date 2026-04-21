#!/usr/bin/env bash
# Log a single badminton session interactively
set -euo pipefail

SKILL_DIR="${COACH_CLAW_DIR:-$HOME/.coach-claw}"
LOG_FILE="$SKILL_DIR/sessions.jsonl"

mkdir -p "$SKILL_DIR"

echo "🏸 coach-claw — log session"
echo ""

# Date
read -rp "Date [$(date +%Y-%m-%d)]: " DATE
DATE="${DATE:-$(date +%Y-%m-%d)}"

# Opponent
read -rp "Opponent (or 'solo drill'): " OPPONENT
OPPONENT="${OPPONENT:-solo drill}"

# Type
echo "Match type: singles / doubles / drill"
read -rp "Type [singles]: " TYPE
TYPE="${TYPE:-singles}"

# Duration
read -rp "Duration (minutes): " DURATION
DURATION="${DURATION:-60}"

# Intensity
echo "Intensity: low / medium / high"
read -rp "Intensity [medium]: " INTENSITY
INTENSITY="${INTENSITY:-medium}"

# Score
read -rp "Score (e.g. 21-18 21-15, or leave blank): " SCORE
SCORE="${SCORE:-}"

# Notes
read -rp "Notes (optional): " NOTES
NOTES="${NOTES:-}"

# Derive load score: low=3, medium=6, high=9; adjust ±1 for duration
LOAD_BASE=6
case "$INTENSITY" in
  low)    LOAD_BASE=3 ;;
  medium) LOAD_BASE=6 ;;
  high)   LOAD_BASE=9 ;;
esac
# Bump load by 1 if duration > 90 min, reduce by 1 if < 30 min
LOAD=$LOAD_BASE
if   [[ "$DURATION" -gt 90 ]]; then LOAD=$((LOAD + 1)); fi
if   [[ "$DURATION" -lt 30 ]]; then LOAD=$((LOAD - 1)); fi
# Clamp to 1–10
[[ $LOAD -lt 1  ]] && LOAD=1
[[ $LOAD -gt 10 ]] && LOAD=10

# Build JSON entry (no external jq dependency for writing)
python3 - "$LOG_FILE" "$DATE" "$OPPONENT" "$TYPE" "$DURATION" "$INTENSITY" "$SCORE" "$NOTES" "$LOAD" << 'PYEOF'
import json, sys
log_file, date, opponent, mtype, duration, intensity, score, notes, load = sys.argv[1:]
entry = {
    "date": date,
    "opponent": opponent,
    "type": mtype,
    "duration_min": int(duration),
    "intensity": intensity,
    "score": score,
    "notes": notes,
    "load_score": int(load),
}
with open(log_file, "a") as f:
    f.write(json.dumps(entry) + "\n")
print("✅ Session logged.")
PYEOF

echo "   Load score: $LOAD / 10"
echo "   Log file  : $LOG_FILE"
