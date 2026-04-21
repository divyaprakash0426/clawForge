# expense-log 💰

> Local-first expense categorizer for bank CSV and SMS exports.

## What it does

`expense-log` imports bank statement CSVs or SMS exports into a local SQLite
ledger, auto-categorises transactions with keyword rules, and generates monthly
spend reports with category breakdowns and month-over-month trends. No cloud
service, no third-party sync — your financial data stays on your device.

## Setup

```bash
# One-time install (creates ~/.expense-log/, checks deps)
bash skills/expense-log/install.sh

# Required env vars
export INPUT_DIR="$HOME/Downloads/bank-exports"
export REPORT_DIR="$HOME/Documents/expense-reports"
```

## Quickstart

```bash
# Import this month's CSV statement
bash skills/expense-log/scripts/import-csv.sh --file ~/Downloads/apr_statement.csv

# Auto-categorise new transactions
bash skills/expense-log/scripts/categorize.sh

# Generate April report
bash skills/expense-log/scripts/report.sh --month 2026-04

# Show 3-month category trend
bash skills/expense-log/scripts/report.sh --trend 3
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and runbook |
| `COMPAT.md` | Per-variant notes |
| `install.sh` | Create `~/.expense-log/`, init SQLite DB, seed default rules |
| `scripts/import-csv.sh` | Import CSV or SMS XML; deduplicate; insert into ledger |
| `scripts/categorize.sh` | Apply keyword rules to uncategorised transactions |
| `scripts/report.sh` | Generate monthly report with trend comparison option |

## CSV format

The importer expects a CSV with at minimum these columns (header names are
case-insensitive, order flexible):

```
date,description,amount,balance
2026-04-10,SWIGGY ORDER #8823421,-450.00,24550.00
```

## Categorisation rules

Default rules are seeded at install time into `~/.expense-log/rules.json`.
Add your own:

```json
[
  {"keyword": "SWIGGY",    "category": "food_delivery"},
  {"keyword": "NETFLIX",   "category": "entertainment"},
  {"keyword": "SALARY",    "category": "income"},
  {"keyword": "RENT",      "category": "rent"}
]
```

## Security tier: L1

All data is local. No network requests. The importer never modifies source bank
files. Automatic backups are created before each write to the ledger DB.

