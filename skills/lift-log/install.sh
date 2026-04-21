#!/usr/bin/env bash
set -euo pipefail

DB_DIR="$HOME/.lift-log"
DB_PATH="${LOGBOOK_PATH:-$DB_DIR/lifts.db}"

echo "💪 lift-log — setup"

# Check required binaries
MISSING=()
for bin in python3 jq; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  exit 1
fi

# Check python sqlite3 module
python3 -c "import sqlite3" 2>/dev/null || {
  echo "❌ Python sqlite3 module unavailable. Install python3-stdlib or equivalent."
  exit 1
}

mkdir -p "$DB_DIR"

# Initialise DB schema if new
python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
db = sys.argv[1]
conn = sqlite3.connect(db)
conn.executescript("""
CREATE TABLE IF NOT EXISTS sets (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  date         TEXT NOT NULL,
  exercise     TEXT NOT NULL,
  set_num      INTEGER,
  reps         INTEGER,
  weight_kg    REAL,
  rpe          REAL,
  notes        TEXT
);
CREATE TABLE IF NOT EXISTS personal_records (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  date         TEXT NOT NULL,
  exercise     TEXT NOT NULL,
  reps         INTEGER,
  weight_kg    REAL
);
""")
conn.commit()
conn.close()
print("DB ready:", db)
PYEOF

echo ""
echo "✅ lift-log is ready."
echo "   DB path : $DB_PATH"
echo ""
echo "Optional env vars:"
echo "  export LOGBOOK_PATH='$DB_PATH'"
echo "  export TELEGRAM_BOT_TOKEN='your-bot-token'   # for PR alerts"
echo "  export TELEGRAM_CHAT_ID='your-chat-id'"

