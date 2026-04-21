#!/usr/bin/env bash
# Import bank CSV (or SMS XML) into the local expense-log SQLite ledger
set -euo pipefail

DB_PATH="${EXPENSE_LOG_DB:-$HOME/.expense-log/ledger.db}"
BACKUP_DIR="$HOME/.expense-log/backups"
INPUT_DIR="${INPUT_DIR:-}"
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) INPUT_FILE="$2"; shift 2 ;;
    --dir)  INPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$INPUT_FILE" && -z "$INPUT_DIR" ]]; then
  echo "Usage: import-csv.sh --file <path>  OR  --dir <directory>"
  echo ""
  echo "  --file: import a single CSV file"
  echo "  --dir : import all .csv files in the directory"
  exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
  echo "❌ Database not found: $DB_PATH"
  echo "   Run install.sh first to initialise the ledger."
  exit 1
fi

# Backup before writing
mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d_%H%M%S)
cp "$DB_PATH" "$BACKUP_DIR/ledger_${TS}.db"

# Collect files to import
FILES=()
if [[ -n "$INPUT_FILE" ]]; then
  [[ -f "$INPUT_FILE" ]] || { echo "❌ File not found: $INPUT_FILE"; exit 1; }
  FILES=("$INPUT_FILE")
elif [[ -n "$INPUT_DIR" ]]; then
  [[ -d "$INPUT_DIR" ]] || { echo "❌ Directory not found: $INPUT_DIR"; exit 1; }
  mapfile -t FILES < <(find "$INPUT_DIR" -maxdepth 1 \( -name "*.csv" -o -name "*.xml" -o -name "*.txt" \) | sort)
  if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No CSV/XML files found in $INPUT_DIR"
    exit 0
  fi
fi

echo "💰 expense-log — import"
echo "  DB: $DB_PATH"
echo ""

for f in "${FILES[@]}"; do
  echo "  Importing: $f"
  python3 - "$DB_PATH" "$f" << 'PYEOF'
import sqlite3, csv, sys, os, hashlib, re
from datetime import datetime

db_path   = sys.argv[1]
src_file  = sys.argv[2]
ext       = os.path.splitext(src_file)[1].lower()

conn = sqlite3.connect(db_path)

inserted   = 0
duplicates = 0
skipped    = 0

if ext == ".csv":
    with open(src_file, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        # Normalise header names to lowercase
        for row in reader:
            row_norm = {k.lower().strip(): v.strip() for k, v in row.items()}
            date_raw = row_norm.get("date", "")
            desc     = row_norm.get("description", row_norm.get("narration", row_norm.get("details", "")))
            amount   = row_norm.get("amount", row_norm.get("debit", "0"))
            balance  = row_norm.get("balance", row_norm.get("closing balance", None))

            if not date_raw or not desc:
                skipped += 1
                continue

            # Normalise date
            for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y", "%m/%d/%Y", "%d %b %Y"):
                try:
                    date_str = datetime.strptime(date_raw, fmt).strftime("%Y-%m-%d")
                    break
                except ValueError:
                    date_str = date_raw

            # Clean amount
            amount_clean = re.sub(r'[^\d.\-]', '', str(amount))
            try:
                amount_f = float(amount_clean) if amount_clean else 0.0
            except ValueError:
                skipped += 1
                continue

            balance_f = None
            if balance:
                bal_clean = re.sub(r'[^\d.\-]', '', str(balance))
                try:
                    balance_f = float(bal_clean)
                except ValueError:
                    pass

            row_hash = hashlib.sha256(f"{date_str}|{desc}|{amount_f}".encode()).hexdigest()[:16]

            try:
                conn.execute(
                    "INSERT INTO transactions (date, description, amount, balance, source_file, row_hash) VALUES (?,?,?,?,?,?)",
                    (date_str, desc, amount_f, balance_f, os.path.basename(src_file), row_hash)
                )
                inserted += 1
            except sqlite3.IntegrityError:
                duplicates += 1

elif ext == ".xml":
    # SMS Backup & Restore XML format: <sms address="..." body="..." date="..." .../>
    import xml.etree.ElementTree as ET
    tree = ET.parse(src_file)
    root = tree.getroot()
    for sms in root.iter("sms"):
        body = sms.get("body", "")
        if not body:
            continue
        # Look for transaction-style SMS: contains amount patterns
        m = re.search(r'Rs\.?\s*([\d,]+\.?\d*)', body, re.IGNORECASE)
        if not m:
            continue
        amount_str = m.group(1).replace(",", "")
        try:
            amount_f = float(amount_str)
        except ValueError:
            continue

        # Guess debit vs credit
        if re.search(r'\b(debited|paid|sent|withdrawn)\b', body, re.IGNORECASE):
            amount_f = -amount_f

        date_ms = int(sms.get("date", 0))
        date_str = datetime.fromtimestamp(date_ms / 1000).strftime("%Y-%m-%d") if date_ms else datetime.now().strftime("%Y-%m-%d")
        desc = body[:200]

        row_hash = hashlib.sha256(f"{date_str}|{desc[:50]}|{amount_f}".encode()).hexdigest()[:16]
        try:
            conn.execute(
                "INSERT INTO transactions (date, description, amount, source_file, row_hash) VALUES (?,?,?,?,?)",
                (date_str, desc, amount_f, os.path.basename(src_file), row_hash)
            )
            inserted += 1
        except sqlite3.IntegrityError:
            duplicates += 1
else:
    print(f"  ⚠️  Unsupported file type: {ext}  (supported: .csv, .xml)")

conn.commit()
conn.close()
print(f"    ✅ {inserted} new rows imported · {duplicates} duplicates skipped · {skipped} invalid rows")
PYEOF
done

echo ""
echo "  Import complete. Run scripts/categorize.sh to label uncategorised rows."
