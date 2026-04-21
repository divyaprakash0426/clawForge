#!/usr/bin/env bash
# Weekly volume and intensity digest for lift-log
set -euo pipefail

DB_PATH="${LOGBOOK_PATH:-$HOME/.lift-log/lifts.db}"

if [[ ! -f "$DB_PATH" ]]; then
  echo "No database found at $DB_PATH. Run install.sh first."
  exit 1
fi

python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
from datetime import date, timedelta

db_path    = sys.argv[1]
today      = date.today()
week_start = str(today - timedelta(days=6))
today_str  = str(today)

conn = sqlite3.connect(db_path)

# Sessions this week
rows = conn.execute("""
    SELECT date, exercise, reps, weight_kg, rpe
    FROM sets
    WHERE date BETWEEN ? AND ?
    ORDER BY date, exercise
""", (week_start, today_str)).fetchall()

if not rows:
    print(f"No sessions logged between {week_start} and {today_str}.")
    conn.close()
    sys.exit(0)

session_dates = sorted(set(r[0] for r in rows))
total_vol = sum(r[2] * r[3] for r in rows)  # reps * weight_kg
rpes = [r[4] for r in rows if r[4] is not None]
avg_rpe = sum(rpes) / len(rpes) if rpes else 0.0

# Volume per exercise
ex_vol = {}
ex_sets = {}
for _, ex, reps, weight, _ in rows:
    ex_vol[ex]  = ex_vol.get(ex, 0) + reps * weight
    ex_sets[ex] = ex_sets.get(ex, 0) + 1

# Previous week volume per exercise
prev_start = str(today - timedelta(days=13))
prev_end   = str(today - timedelta(days=7))
prev_rows  = conn.execute("""
    SELECT exercise, reps, weight_kg FROM sets
    WHERE date BETWEEN ? AND ?
""", (prev_start, prev_end)).fetchall()
prev_vol = {}
for ex, reps, weight in prev_rows:
    prev_vol[ex] = prev_vol.get(ex, 0) + reps * weight

# PRs this week
pr_rows = conn.execute("""
    SELECT exercise, reps, weight_kg FROM personal_records
    WHERE date BETWEEN ? AND ?
""", (week_start, today_str)).fetchall()

conn.close()

print(f"\n💪 lift-log weekly brief  {week_start} → {today_str}")
print(f"Sessions     : {len(session_dates)}")
print(f"Total volume : {total_vol:,.0f} kg")
print(f"Avg RPE      : {avg_rpe:.1f}")
print()
print("Exercise breakdown:")
for ex in sorted(ex_vol, key=lambda e: ex_vol[e], reverse=True):
    vol  = ex_vol[ex]
    sets = ex_sets[ex]
    prev = prev_vol.get(ex, 0)
    if prev == 0:
        arrow = "🆕 new"
    elif vol > prev * 1.05:
        arrow = "↑ vs last week"
    elif vol < prev * 0.80:
        arrow = "↓ low volume — check recovery"
    else:
        arrow = "→ same"
    print(f"  {ex:<28s} {vol:>8,.0f} kg × {sets} sets  {arrow}")

if pr_rows:
    print()
    print("🏆 New PRs this week:")
    for ex, reps, weight in pr_rows:
        print(f"  {ex}: {reps}×{weight}kg")
PYEOF
