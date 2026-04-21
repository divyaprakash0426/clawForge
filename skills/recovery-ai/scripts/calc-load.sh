#!/usr/bin/env bash
# Calculate acute (7-day) and chronic (28-day) training load + ACWR
set -euo pipefail

WORKOUT_LOG_PATH="${WORKOUT_LOG_PATH:-}"

if [[ -z "$WORKOUT_LOG_PATH" ]]; then
  echo "❌ WORKOUT_LOG_PATH is not set."
  echo "   Set it to your lift-log SQLite DB or coach-claw sessions.jsonl path."
  exit 1
fi

if [[ ! -f "$WORKOUT_LOG_PATH" ]]; then
  echo "❌ File not found: $WORKOUT_LOG_PATH"
  exit 1
fi

python3 - "$WORKOUT_LOG_PATH" << 'PYEOF'
import sys, json, sqlite3, os
from datetime import date, timedelta

log_path = sys.argv[1]
today    = date.today()

def load_from_jsonl(path):
    """Load daily load scores from coach-claw sessions.jsonl."""
    loads = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                d  = entry.get("date")
                ls = entry.get("load_score", 0)
                if d:
                    loads[d] = loads.get(d, 0) + ls
            except Exception:
                pass
    return loads

def load_from_sqlite(path):
    """Derive daily load from lift-log sets: sum(reps * weight_kg) per day → normalise."""
    conn = sqlite3.connect(path)
    rows = conn.execute(
        "SELECT date, reps, weight_kg, rpe FROM sets ORDER BY date"
    ).fetchall()
    conn.close()
    loads = {}
    for d, reps, weight, rpe in rows:
        # Approximate load: volume * RPE factor (rpe/10, default 0.7)
        rpe_factor = (rpe / 10.0) if rpe else 0.7
        load = (reps * weight * rpe_factor) / 100.0  # scale to 0–10 range approx
        loads[d] = loads.get(d, 0) + load
    # Normalise to 0–10 scale using max value in window
    if loads:
        max_load = max(loads.values())
        if max_load > 0:
            loads = {d: min(10.0, v * 10.0 / max_load) for d, v in loads.items()}
    return loads

# Auto-detect format
ext = os.path.splitext(log_path)[1].lower()
if ext in ('.jsonl', '.json'):
    daily_loads = load_from_jsonl(log_path)
else:
    daily_loads = load_from_sqlite(log_path)

def avg_load_window(loads, days_back):
    total = 0.0
    count = 0
    for i in range(days_back):
        d = str(today - timedelta(days=i))
        total += loads.get(d, 0)
        count += 1
    return total / count if count else 0

acute   = avg_load_window(daily_loads, 7)
chronic = avg_load_window(daily_loads, 28)
acwr    = acute / chronic if chronic > 0 else 0

print(f"\n🧘 recovery-ai — training load  ({today})\n")
print(f"  Acute load  (7-day avg)   : {acute:.1f} AU")
print(f"  Chronic load (28-day avg) : {chronic:.1f} AU")
print(f"  ACWR                      : {acwr:.2f}")
if acwr == 0:
    print("\n  ⚠️  Insufficient data (< 3 days). Load scores may not be accurate.")
elif acwr > 1.5:
    print("\n  🔴 HIGH RISK — acute load is significantly elevated")
elif acwr > 1.2:
    print("\n  🟡 ELEVATED — workload ratio is above optimal zone")
elif acwr < 0.8:
    print("\n  🔵 LOW — detraining risk if this continues for > 2 weeks")
else:
    print("\n  🟢 OPTIMAL — workload ratio is in the 0.8–1.2 sweet spot")
PYEOF
