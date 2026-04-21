#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import OrderedDict
from datetime import date, datetime
from pathlib import Path


def rows_from_source(source: str):
    if source == "-":
        return list(csv.DictReader(sys.stdin))
    return list(csv.DictReader(Path(source).read_text(encoding="utf-8").splitlines()))


def parse_date(value: str) -> date:
    return datetime.strptime(value.strip(), "%Y-%m-%d").date()


def summarize(rows: list[dict], target_ml: int) -> dict:
    daily: dict[str, float] = OrderedDict()
    for row in rows:
        day = parse_date(row["date"]).isoformat()
        amount = float(row.get("ml") or row.get("amount_ml") or 0)
        daily[day] = daily.get(day, 0.0) + amount
    ordered = [{"date": day, "ml": round(amount, 1), "met_target": amount >= target_ml} for day, amount in sorted(daily.items())]
    last_seven = ordered[-7:]
    average = round(sum(item["ml"] for item in last_seven) / len(last_seven), 1) if last_seven else 0.0
    streak = 0
    for item in reversed(ordered):
        if item["met_target"]:
            break
        streak += 1
    return {"target_ml": target_ml, "days": ordered, "seven_day_average_ml": average, "below_target_streak": streak}


def to_markdown(payload: dict) -> str:
    lines = ["# hydration-check report", "", f"- Daily target: {payload['target_ml']} ml", f"- 7-day average: {payload['seven_day_average_ml']} ml", f"- Below-target streak: {payload['below_target_streak']} day(s)", "", "## Daily totals"]
    for item in payload["days"]:
        status = "met" if item["met_target"] else "below"
        lines.append(f"- {item['date']}: {item['ml']} ml ({status})")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize hydration CSV logs.")
    parser.add_argument("source", help="CSV file path or - for stdin.")
    parser.add_argument("--target-ml", type=int, default=2500, help="Daily hydration target in milliliters.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    payload = summarize(rows_from_source(args.source), args.target_ml)
    if args.markdown:
        sys.stdout.write(to_markdown(payload))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
