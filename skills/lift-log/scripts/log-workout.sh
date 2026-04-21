#!/usr/bin/env bash
# Interactive workout set logger
set -euo pipefail

DB_PATH="${LOGBOOK_PATH:-$HOME/.lift-log/lifts.db}"
mkdir -p "$(dirname "$DB_PATH")"

echo "💪 lift-log — log workout"
echo ""

read -rp "Date [$(date +%Y-%m-%d)]: " DATE
DATE="${DATE:-$(date +%Y-%m-%d)}"

echo "Enter sets. Format: exercise / sets x reps x weight_kg [/ RPE] [/ notes]"
echo "Example: Barbell Squat / 3x5x100 / 8 / felt solid"
echo "Type 'done' to finish."
echo ""

ENTRIES=()
SET_NUM=1
while true; do
  read -rp "Set $SET_NUM: " LINE
  [[ "$LINE" == "done" || -z "$LINE" ]] && break
  ENTRIES+=("$LINE")
  SET_NUM=$((SET_NUM + 1))
done

if [[ ${#ENTRIES[@]} -eq 0 ]]; then
  echo "No sets entered."
  exit 0
fi

python3 - "$DB_PATH" "$DATE" "${ENTRIES[@]}" << 'PYEOF'
import sqlite3, sys, re

db_path = sys.argv[1]
date    = sys.argv[2]
entries = sys.argv[3:]

conn = sqlite3.connect(db_path)

inserted = 0
for raw in entries:
    parts = [p.strip() for p in raw.split("/")]
    if len(parts) < 2:
        print(f"  ⚠️  Skipped (bad format): {raw}")
        continue
    exercise = parts[0]
    set_str  = parts[1]  # e.g. 3x5x100 or 5x80
    rpe   = float(parts[2]) if len(parts) > 2 and parts[2] else None
    notes = parts[3] if len(parts) > 3 else ""

    # Parse sets x reps x weight or reps x weight
    m = re.match(r'(\d+)x(\d+)x([\d.]+)', set_str)
    if m:
        num_sets = int(m.group(1))
        reps     = int(m.group(2))
        weight   = float(m.group(3))
    else:
        m2 = re.match(r'(\d+)x([\d.]+)', set_str)
        if m2:
            num_sets = 1
            reps     = int(m2.group(1))
            weight   = float(m2.group(2))
        else:
            print(f"  ⚠️  Could not parse sets from: {set_str}")
            continue

    for s in range(1, num_sets + 1):
        conn.execute(
            "INSERT INTO sets (date, exercise, set_num, reps, weight_kg, rpe, notes) VALUES (?,?,?,?,?,?,?)",
            (date, exercise, s, reps, weight, rpe, notes)
        )
        inserted += 1

conn.commit()
conn.close()
print(f"✅ {inserted} set(s) logged to {db_path}")
PYEOF
