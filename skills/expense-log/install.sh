#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.expense-log"
DB_PATH="$CONFIG_DIR/ledger.db"
BACKUP_DIR="$CONFIG_DIR/backups"

echo "💰 expense-log — setup"

# Check required binaries
MISSING=()
for bin in python3; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  exit 1
fi

python3 -c "import sqlite3" 2>/dev/null || {
  echo "❌ Python sqlite3 module unavailable."
  exit 1
}

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"

# Check INPUT_DIR and REPORT_DIR
if [[ -z "${INPUT_DIR:-}" ]]; then
  echo "⚠️  INPUT_DIR not set — set it to your bank export folder."
fi
if [[ -z "${REPORT_DIR:-}" ]]; then
  echo "⚠️  REPORT_DIR not set — set it to where reports should be written."
fi

# Initialise DB
python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
db = sys.argv[1]
conn = sqlite3.connect(db)
conn.executescript("""
CREATE TABLE IF NOT EXISTS transactions (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  date        TEXT NOT NULL,
  description TEXT NOT NULL,
  amount      REAL NOT NULL,
  balance     REAL,
  category    TEXT,
  source_file TEXT,
  row_hash    TEXT UNIQUE
);
""")
conn.commit()
conn.close()
print("DB ready:", db)
PYEOF

# Seed default categorisation rules
if [[ ! -f "$CONFIG_DIR/rules.json" ]]; then
  cat > "$CONFIG_DIR/rules.json" << 'EOF'
[
  {"keyword": "SWIGGY",      "category": "food_delivery"},
  {"keyword": "ZOMATO",      "category": "food_delivery"},
  {"keyword": "NETFLIX",     "category": "entertainment"},
  {"keyword": "SPOTIFY",     "category": "entertainment"},
  {"keyword": "AMAZON",      "category": "shopping"},
  {"keyword": "FLIPKART",    "category": "shopping"},
  {"keyword": "PETROL",      "category": "transport"},
  {"keyword": "OLA",         "category": "transport"},
  {"keyword": "UBER",        "category": "transport"},
  {"keyword": "SALARY",      "category": "income"},
  {"keyword": "RENT",        "category": "rent"},
  {"keyword": "ELECTRICITY", "category": "utilities"},
  {"keyword": "BROADBAND",   "category": "utilities"}
]
EOF
  echo "✅ Created default rules at $CONFIG_DIR/rules.json"
fi

echo ""
echo "✅ expense-log is ready."
echo "   DB       : $DB_PATH"
echo "   Rules    : $CONFIG_DIR/rules.json"
echo "   Backups  : $BACKUP_DIR"
echo ""
echo "Required env vars:"
echo "  export INPUT_DIR='\$HOME/Downloads/bank-exports'"
echo "  export REPORT_DIR='\$HOME/Documents/expense-reports'"

