#!/usr/bin/env bash
# Generate a monthly expense report with optional multi-month trend
set -euo pipefail

DB_PATH="${EXPENSE_LOG_DB:-$HOME/.expense-log/ledger.db}"
REPORT_DIR="${REPORT_DIR:-$HOME/Documents/expense-reports}"
MONTH=""
TREND=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --month) MONTH="$2"; shift 2 ;;
    --trend) TREND="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

MONTH="${MONTH:-$(date +%Y-%m)}"

if [[ ! -f "$DB_PATH" ]]; then
  echo "❌ Database not found: $DB_PATH — run install.sh first."
  exit 1
fi

mkdir -p "$REPORT_DIR"

python3 - "$DB_PATH" "$MONTH" "$TREND" "$REPORT_DIR" << 'PYEOF'
import sqlite3, sys, os
from datetime import datetime, date
from calendar import monthrange

db_path    = sys.argv[1]
month_str  = sys.argv[2]
trend_n    = int(sys.argv[3])
report_dir = sys.argv[4]

conn = sqlite3.connect(db_path)

def get_month_data(ym):
    """Return {category: total_spent} for a YYYY-MM month."""
    y, m = map(int, ym.split("-"))
    _, last_day = monthrange(y, m)
    start = f"{ym}-01"
    end   = f"{ym}-{last_day:02d}"
    rows = conn.execute("""
        SELECT COALESCE(category, 'uncategorised') as cat, SUM(ABS(amount)) as total
        FROM transactions
        WHERE date BETWEEN ? AND ? AND amount < 0
        GROUP BY cat ORDER BY total DESC
    """, (start, end)).fetchall()
    income = conn.execute("""
        SELECT SUM(amount) FROM transactions
        WHERE date BETWEEN ? AND ? AND amount > 0
    """, (start, end)).fetchone()[0] or 0
    return dict(rows), income

def months_back(n):
    """Return list of YYYY-MM strings for the last n months including current."""
    result = []
    y, m = map(int, month_str.split("-"))
    for _ in range(n):
        result.append(f"{y}-{m:02d}")
        m -= 1
        if m == 0:
            m = 12
            y -= 1
    return list(reversed(result))

# ── Single month report ───────────────────────────────────────────────────────
data, income = get_month_data(month_str)

if not data:
    print(f"No expense data found for {month_str}.")
    conn.close()
    sys.exit(0)

total_spend = sum(data.values())

lines = [f"\n💰 expense-log — {month_str}\n"]
lines.append(f"{'Category':<22} {'Spent':>10}  {'%':>6}")
lines.append("-" * 44)

for cat, amount in data.items():
    pct = amount / total_spend * 100 if total_spend else 0
    flag = "  ⚠️" if pct > 40 and cat != "income" else ""
    lines.append(f"  {cat:<20} {amount:>10,.2f}  {pct:>5.1f}%{flag}")

lines.append("-" * 44)
lines.append(f"  {'Total spend':<20} {total_spend:>10,.2f}")
if income:
    lines.append(f"  {'Income (est.)':<20} {income:>10,.2f}")
    net = income - total_spend
    pct_saved = net / income * 100 if income else 0
    lines.append(f"  {'Net savings':<20} {net:>10,.2f}  ({pct_saved:.1f}%)")

output = "\n".join(lines)
print(output)

# ── Trend mode ────────────────────────────────────────────────────────────────
if trend_n > 1:
    month_list = months_back(trend_n)
    month_data = {m: get_month_data(m)[0] for m in month_list}
    all_cats   = sorted(set(c for d in month_data.values() for c in d))

    print(f"\n📊 {trend_n}-month trend ({month_list[0]} → {month_list[-1]})\n")
    header = f"  {'Category':<22}" + "".join(f"  {m:>10}" for m in month_list)
    print(header)
    print("-" * (24 + trend_n * 12))
    for cat in all_cats:
        row = f"  {cat:<22}"
        for m in month_list:
            val = month_data[m].get(cat, 0)
            row += f"  {val:>10,.0f}"
        print(row)

# ── Write Markdown report ─────────────────────────────────────────────────────
report_path = os.path.join(report_dir, f"expense_{month_str}.md")
with open(report_path, "w") as f:
    f.write(f"# Expense Report — {month_str}\n\n")
    f.write("```\n")
    f.write(output)
    f.write("\n```\n")

conn.close()
print(f"\n  📄 Report saved: {report_path}")
PYEOF
