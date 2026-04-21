#!/usr/bin/env bash
# Apply keyword rules to uncategorised expense transactions
set -euo pipefail

DB_PATH="${EXPENSE_LOG_DB:-$HOME/.expense-log/ledger.db}"
RULES_FILE="$HOME/.expense-log/rules.json"

if [[ ! -f "$DB_PATH" ]]; then
  echo "❌ Database not found: $DB_PATH — run install.sh first."
  exit 1
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "❌ Rules file not found: $RULES_FILE — run install.sh to seed defaults."
  exit 1
fi

echo "💰 expense-log — categorize"

python3 - "$DB_PATH" "$RULES_FILE" << 'PYEOF'
import sqlite3, json, sys

db_path    = sys.argv[1]
rules_file = sys.argv[2]

with open(rules_file) as f:
    rules = json.load(f)

conn = sqlite3.connect(db_path)

uncategorised = conn.execute(
    "SELECT id, description FROM transactions WHERE category IS NULL OR category = ''"
).fetchall()

if not uncategorised:
    print("  ✅ All transactions are already categorised.")
    conn.close()
    sys.exit(0)

updated = 0
for tx_id, desc in uncategorised:
    desc_upper = desc.upper()
    matched = None
    for rule in rules:
        if rule["keyword"].upper() in desc_upper:
            matched = rule["category"]
            break
    if matched:
        conn.execute("UPDATE transactions SET category=? WHERE id=?", (matched, tx_id))
        updated += 1

conn.commit()

remaining = conn.execute(
    "SELECT COUNT(*) FROM transactions WHERE category IS NULL OR category = ''"
).fetchone()[0]

conn.close()

print(f"  ✅ Categorised: {updated} rows")
if remaining:
    print(f"  ⚠️  Still uncategorised: {remaining} rows")
    print(f"     Add keywords to {rules_file} to auto-classify them.")
else:
    print("  ✅ All transactions categorised.")
PYEOF
