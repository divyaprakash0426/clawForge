---
name: expense-log
description: Local-first expense categorizer for bank SMS and CSV exports.
version: 1.0.0
metadata:
  openclaw:
    emoji: "💰"
    requires:
      bins: ["python3", "sqlite3", "jq"]
      env: ["INPUT_DIR", "REPORT_DIR"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: ["finance", "expenses", "csv", "analytics"]
---

# expense-log

## Purpose

Parse bank CSV or SMS exports into a local SQLite ledger, auto-categorise
transactions using keyword rules, and generate monthly spend reports — all
without any cloud service. Financial data never leaves your machine.

Supported input formats:
- Generic bank CSV (date, description, amount, balance)
- SMS export from Android (`.xml` or `.txt` from SMS Backup & Restore)
- Custom format adapters configurable via `~/.expense-log/adapters.json`

## Runbook

1. **Pre-flight** — verify `python3` and `sqlite3` are available.  
   Ensure `INPUT_DIR` points to the folder where your bank exports are dropped.  
   Ensure `REPORT_DIR` is writable for HTML/Markdown report output.  
   On first run, `scripts/import-csv.sh` creates `~/.expense-log/ledger.db`.

2. **Import** — run `scripts/import-csv.sh [--file <path>|--dir <INPUT_DIR>]`:
   - Auto-detects the file type (CSV or SMS XML)
   - Deduplicates rows using a hash of `(date, description, amount)`
   - Inserts new transactions into the `transactions` table with `category = NULL`
   - Prints an import summary: `N new / M duplicates skipped`

3. **Categorise** — run `scripts/categorize.sh`:
   - Reads `~/.expense-log/rules.json` (keyword → category mapping)
   - Updates `category` for all uncategorised rows via `LIKE` matching on
     `description`
   - Prints any transactions still uncategorised (review manually)
   - You may add rules interactively or by editing `rules.json` directly

4. **Report** — run `scripts/report.sh [--month YYYY-MM]`:
   - Defaults to the current calendar month
   - Groups spend by category and prints a ranked table
   - Flags the highest spend category with ⚠️ if it exceeds 40% of total
   - Outputs a Markdown file to `REPORT_DIR/expense_<YYYY-MM>.md`

5. **Trend** — `scripts/report.sh --trend 3` prints a 3-month comparison table
   side by side, showing category-level month-over-month delta.

## Stop conditions

1. Abort if `python3` is missing — SQLite operations use the stdlib `sqlite3` module.
2. Never delete or modify source bank files in `INPUT_DIR`.
3. Do not execute any write to `ledger.db` without first taking a backup copy to
   `~/.expense-log/backups/ledger_<timestamp>.db`.
4. Do not transmit financial data to any external service or API.
5. Abort for `nullclaw` variant — no shell execution.

## Output format

### Transaction row (`transactions` table)
```
id | date       | description           | amount  | category
 1 | 2026-04-10 | SWIGGY ORDER #8823421 | -450.00 | food_delivery
 2 | 2026-04-12 | SALARY CREDIT         | 75000   | income
```

### Monthly report (stdout + Markdown)
```
💰 expense-log — April 2026

Category          | Spent (₹) | % of total | vs Mar
------------------|-----------|-----------|---------
Food & Delivery   |  8,450    |   28.2%   | +12%  ⚠️
Rent              |  15,000   |   50.0%   | —
Transport         |  2,100    |    7.0%   | -5%
Entertainment     |  1,800    |    6.0%   | +40%
Uncategorised     |  1,650    |    5.5%   | review

Total spend       :  29,000 ₹
Income (estimated):  75,000 ₹
Net savings       :  46,000 ₹  (61.3%)
```

## Example invocations

- `scripts/import-csv.sh --file apr_statement.csv` — import April statement
- `scripts/categorize.sh` — auto-categorise uncategorised rows
- `scripts/report.sh --month 2026-04` — generate April expense report
- `scripts/report.sh --trend 3` — show 3-month category trend
- "Import my latest bank CSV and show this month's spend by category."
- "How much did I spend on food last month?"
