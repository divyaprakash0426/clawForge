---
name: invoice-ledger
description: Age invoice CSV exports into overdue buckets and cash-collection summaries.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📈"
    requires:
      bins: ['python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: partial
      nanobot: full
      ironclaw: full
    security_tier: L2
    tags: ['finance', 'invoices', 'accounts-receivable', 'reporting']
---

# invoice-ledger

## Purpose

Summarize accounts receivable from exported invoice CSVs without moving finance data into SaaS tools.

## Runbook

1. Provide a CSV with invoice id, client, due date, amount, and either status or paid date.
2. Run `scripts/age.py` to bucket open invoices into current, 1-30, 31-60, and 61+ day overdue ranges.
3. Use the output to prioritize follow-up, not to overwrite the source ledger.
4. Keep reports local because invoice data may contain sensitive customer information.

## Stop conditions

1. Abort if the CSV columns do not map cleanly to due date and amount.
2. Abort before contacting customers based on stale or duplicate invoice exports.
3. Abort if the active variant cannot keep the finance data local.

## Output format

- Aging buckets by amount
- Open invoice list with overdue days
- Collected vs open totals

## Example invocations

- `python3 skills/invoice-ledger/scripts/age.py invoices.csv --markdown`
- `cat invoices.csv | python3 skills/invoice-ledger/scripts/age.py - --today 2026-04-01`
