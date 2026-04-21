#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import sys
from datetime import date, datetime
from pathlib import Path

BUCKETS = [(0, 0, "current"), (1, 30, "1-30"), (31, 60, "31-60"), (61, 10_000, "61+")]


def load_rows(source: str) -> list[dict]:
    if source == "-":
        return list(csv.DictReader(sys.stdin))
    return list(csv.DictReader(Path(source).read_text(encoding="utf-8").splitlines()))


def parse_day(value: str) -> date:
    return datetime.strptime(value.strip(), "%Y-%m-%d").date()


def normalize_amount(row: dict) -> float:
    raw = row.get("amount") or row.get("total") or row.get("balance") or "0"
    return float(str(raw).replace(",", "").strip())


def build_report(rows: list[dict], today: date) -> dict:
    bucket_totals = {label: 0.0 for _, _, label in BUCKETS}
    open_invoices = []
    collected_total = 0.0
    for row in rows:
        amount = normalize_amount(row)
        status = (row.get("status") or "").strip().lower()
        paid_on = (row.get("paid_on") or row.get("paid") or "").strip()
        if status == "paid" or paid_on:
            collected_total += amount
            continue
        due_on = parse_day(row["due_on"] if "due_on" in row else row["due_date"])
        overdue_days = max((today - due_on).days, 0)
        label = next(bucket for low, high, bucket in BUCKETS if low <= overdue_days <= high)
        bucket_totals[label] += amount
        open_invoices.append({
            "invoice_id": row.get("invoice_id") or row.get("id") or "unknown",
            "client": row.get("client") or row.get("customer") or "unknown",
            "amount": round(amount, 2),
            "due_on": due_on.isoformat(),
            "overdue_days": overdue_days,
            "bucket": label,
        })
    open_total = round(sum(item["amount"] for item in open_invoices), 2)
    return {
        "as_of": today.isoformat(),
        "bucket_totals": {key: round(value, 2) for key, value in bucket_totals.items()},
        "open_total": open_total,
        "collected_total": round(collected_total, 2),
        "open_invoices": sorted(open_invoices, key=lambda item: item["overdue_days"], reverse=True),
    }


def to_markdown(payload: dict) -> str:
    lines = ["# invoice-ledger report", "", f"- As of: {payload['as_of']}", f"- Open total: {payload['open_total']}", f"- Collected total: {payload['collected_total']}", "", "## Aging buckets"]
    for bucket, amount in payload["bucket_totals"].items():
        lines.append(f"- {bucket}: {amount}")
    lines.extend(["", "## Open invoices"])
    for item in payload["open_invoices"]:
        lines.append(f"- {item['invoice_id']} / {item['client']} — {item['amount']} due {item['due_on']} ({item['overdue_days']} days, {item['bucket']})")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Build an AR aging report from invoice CSV data.")
    parser.add_argument("source", help="CSV file path or - for stdin.")
    parser.add_argument("--today", default=date.today().isoformat(), help="Report date in YYYY-MM-DD format.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    payload = build_report(load_rows(args.source), parse_day(args.today))
    if args.markdown:
        sys.stdout.write(to_markdown(payload))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
