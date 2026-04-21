#!/usr/bin/env bash
# Compare today's top sets against historical maxima; log and alert on PRs
set -euo pipefail

DB_PATH="${LOGBOOK_PATH:-$HOME/.lift-log/lifts.db}"

if [[ ! -f "$DB_PATH" ]]; then
  echo "No database found at $DB_PATH. Run install.sh first."
  exit 1
fi

python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
from datetime import date

db_path = sys.argv[1]
today   = str(date.today())
conn    = sqlite3.connect(db_path)

# Today's best set per exercise
today_bests = conn.execute("""
    SELECT exercise, reps, weight_kg
    FROM sets
    WHERE date = ?
    ORDER BY weight_kg DESC, reps DESC
""", (today,)).fetchall()

if not today_bests:
    print("No sets logged today.")
    conn.close()
    sys.exit(0)

seen = set()
new_prs = []

print(f"\n💪 PR check — {today}\n")
for exercise, reps, weight in today_bests:
    if exercise in seen:
        continue
    seen.add(exercise)

    prev = conn.execute("""
        SELECT reps, weight_kg FROM sets
        WHERE exercise = ? AND date < ?
        ORDER BY weight_kg DESC, reps DESC LIMIT 1
    """, (exercise, today)).fetchone()

    if prev is None:
        print(f"  {exercise}: first session on record — {reps}×{weight}kg")
        continue

    prev_reps, prev_weight = prev
    if weight > prev_weight or (weight == prev_weight and reps > prev_reps):
        print(f"  🏆 PR  {exercise}: {reps}×{weight}kg  (prev {prev_reps}×{prev_weight}kg)")
        conn.execute(
            "INSERT INTO personal_records (date, exercise, reps, weight_kg) VALUES (?,?,?,?)",
            (today, exercise, reps, weight)
        )
        new_prs.append(f"{exercise}: {reps}×{weight}kg")
    else:
        print(f"  ✓  {exercise}: {reps}×{weight}kg  (best {prev_reps}×{prev_weight}kg)")

conn.commit()
conn.close()

if new_prs:
    print(f"\n{len(new_prs)} new PR(s) this session!")
PYEOF

# Optional Telegram alert for PRs
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  PR_MSG=$(python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
from datetime import date
db_path = sys.argv[1]
today = str(date.today())
conn = sqlite3.connect(db_path)
prs = conn.execute("SELECT exercise, reps, weight_kg FROM personal_records WHERE date=?", (today,)).fetchall()
conn.close()
if prs:
    lines = ["🏆 New PRs today!"] + [f"  {e}: {r}×{w}kg" for e, r, w in prs]
    print("\n".join(lines))
PYEOF
  )
  if [[ -n "$PR_MSG" ]]; then
    curl -s -o /dev/null -X POST \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${PR_MSG}" || true
  fi
fi
