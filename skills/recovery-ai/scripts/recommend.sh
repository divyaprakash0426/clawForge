#!/usr/bin/env bash
# Full recovery recommendation combining ACWR and optional HRV signal
set -euo pipefail

WORKOUT_LOG_PATH="${WORKOUT_LOG_PATH:-}"
HRV_SOURCE_PATH="${HRV_SOURCE_PATH:-}"
LOG_DIR="$HOME/.recovery-ai"

if [[ -z "$WORKOUT_LOG_PATH" || ! -f "$WORKOUT_LOG_PATH" ]]; then
  echo "❌ WORKOUT_LOG_PATH is not set or file does not exist."
  exit 1
fi

mkdir -p "$LOG_DIR"

python3 - "$WORKOUT_LOG_PATH" "${HRV_SOURCE_PATH:-}" "$LOG_DIR/log.jsonl" << 'PYEOF'
import sys, json, sqlite3, os
from datetime import date, timedelta

log_path     = sys.argv[1]
hrv_path     = sys.argv[2] if len(sys.argv) > 2 else ""
out_log_path = sys.argv[3]
today        = date.today()

# ── Load training load ──────────────────────────────────────────────────────

def load_from_jsonl(path):
    loads = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                e = json.loads(line)
                d = e.get("date")
                if d:
                    loads[d] = loads.get(d, 0) + e.get("load_score", 0)
            except Exception:
                pass
    return loads

def load_from_sqlite(path):
    conn = sqlite3.connect(path)
    rows = conn.execute("SELECT date, reps, weight_kg, rpe FROM sets ORDER BY date").fetchall()
    conn.close()
    loads = {}
    for d, reps, weight, rpe in rows:
        rpe_factor = (rpe / 10.0) if rpe else 0.7
        loads[d] = loads.get(d, 0) + (reps * weight * rpe_factor) / 100.0
    if loads:
        mx = max(loads.values())
        if mx > 0:
            loads = {d: min(10.0, v * 10.0 / mx) for d, v in loads.items()}
    return loads

ext = os.path.splitext(log_path)[1].lower()
daily_loads = load_from_jsonl(log_path) if ext in ('.jsonl', '.json') else load_from_sqlite(log_path)

def avg_load_window(loads, days_back):
    return sum(loads.get(str(today - timedelta(days=i)), 0) for i in range(days_back)) / days_back

acute   = avg_load_window(daily_loads, 7)
chronic = avg_load_window(daily_loads, 28)
acwr    = acute / chronic if chronic > 0 else 0

# ── Load HRV ───────────────────────────────────────────────────────────────

hrv_today    = None
hrv_baseline = None
hrv_pct_drop = None

if hrv_path and os.path.isfile(hrv_path):
    hrv_readings = {}
    try:
        with open(hrv_path) as f:
            first = f.readline().strip()
        if first.startswith("{"):
            # JSONL
            with open(hrv_path) as f:
                for line in f:
                    try:
                        e = json.loads(line.strip())
                        hrv_readings[e["date"]] = float(e["hrv_ms"])
                    except Exception:
                        pass
        else:
            # CSV: date,hrv_ms
            import csv
            with open(hrv_path) as f:
                reader = csv.DictReader(f)
                for row in reader:
                    hrv_readings[row["date"].strip()] = float(row["hrv_ms"])
    except Exception as ex:
        print(f"  ⚠️  Could not parse HRV file: {ex}")

    today_str = str(today)
    hrv_today = hrv_readings.get(today_str)

    # 30-day baseline
    baseline_values = [
        hrv_readings[str(today - timedelta(days=i))]
        for i in range(1, 31)
        if str(today - timedelta(days=i)) in hrv_readings
    ]
    if baseline_values:
        hrv_baseline = sum(baseline_values) / len(baseline_values)
        if hrv_today is not None:
            hrv_pct_drop = (hrv_baseline - hrv_today) / hrv_baseline * 100

hrv_suppressed = hrv_pct_drop is not None and hrv_pct_drop > 10

# ── Decision logic ─────────────────────────────────────────────────────────

if acwr == 0:
    recommendation = "unknown"
    reason = "insufficient_data"
elif acwr > 1.5:
    recommendation = "full_rest"
    reason = "acwr_critical"
elif acwr > 1.2 and hrv_suppressed:
    recommendation = "full_rest"
    reason = "elevated_acwr+hrv_suppressed"
elif acwr > 1.2:
    recommendation = "active_recovery"
    reason = "elevated_acwr"
elif acwr < 0.8:
    recommendation = "train_as_planned"
    reason = "low_acwr_detraining_risk"
else:
    recommendation = "train_as_planned"
    reason = "optimal_acwr"

# ── Output ─────────────────────────────────────────────────────────────────

print(f"\n🧘 recovery-ai  —  {today}\n")
print(f"  Training load (7-day acute)   : {acute:.1f} AU")
print(f"  Training load (28-day chronic): {chronic:.1f} AU")
print(f"  ACWR                          : {acwr:.2f}")
if hrv_today is not None:
    baseline_str = f"baseline {hrv_baseline:.0f} ms" if hrv_baseline else "no baseline"
    drop_str = f"↓ {hrv_pct_drop:.1f}%" if hrv_pct_drop is not None else ""
    print(f"  HRV today                     : {hrv_today:.0f} ms  ({baseline_str}  {drop_str})")
else:
    print(f"  HRV today                     : not available")

print()
rec_labels = {
    "full_rest":        ("🔴", "FULL REST"),
    "active_recovery":  ("🟡", "ACTIVE RECOVERY"),
    "train_as_planned": ("🟢", "TRAIN AS PLANNED"),
    "unknown":          ("⚪", "UNKNOWN — LOG MORE SESSIONS"),
}
emoji, label = rec_labels.get(recommendation, ("⚪", recommendation.upper()))
print(f"  {emoji}  Recommendation: {label}")

suggestions = {
    "full_rest":        "Complete rest. No structured training today.",
    "active_recovery":  "30–40 min easy walk, swim, or Hatha Yoga flow. No high-intensity.",
    "train_as_planned": "Load is sustainable — proceed with your planned session.",
    "low_acwr_detraining_risk": "Load is low — consider increasing training volume gradually.",
    "unknown":          "Log at least 3 days of sessions for a reliable recommendation.",
}
print(f"  Suggestion: {suggestions.get(reason, suggestions.get(recommendation, ''))}")

# ── Persist log entry ───────────────────────────────────────────────────────
entry = {
    "date": str(today),
    "acwr": round(acwr, 3),
    "hrv_ms": hrv_today,
    "hrv_baseline_ms": round(hrv_baseline, 1) if hrv_baseline else None,
    "recommendation": recommendation,
    "reason": reason,
}
with open(out_log_path, "a") as f:
    f.write(json.dumps(entry) + "\n")
PYEOF
