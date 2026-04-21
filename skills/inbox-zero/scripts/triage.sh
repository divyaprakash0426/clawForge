#!/usr/bin/env bash
set -euo pipefail

input_json="$(cat)"
if [ -z "$input_json" ]; then
  echo "inbox-zero triage: expected inbox JSON on stdin." >&2
  exit 1
fi

INPUT_JSON="$input_json" python3 - <<'PY'
import json
import os

messages = json.loads(os.environ["INPUT_JSON"])
priority_keywords = ["urgent", "action required", "invoice", "deadline"]
routine_keywords = ["newsletter", "digest", "notification", "receipt", "noreply", "no-reply"]

items = []
priority_items = []
counts = {"priority": 0, "routine": 0, "defer": 0}

for message in messages:
    haystack = f"{message.get('from', '')} {message.get('subject', '')}".lower()
    if any(keyword in haystack for keyword in priority_keywords):
        category = "priority"
        action = "Review today and draft a reply subject."
    elif any(keyword in haystack for keyword in routine_keywords):
        category = "routine"
        action = "Batch later, archive, or filter automatically."
    else:
        category = "defer"
        action = "Leave unread for the next focused triage block."

    record = {
        "message_id": message.get("message_id", ""),
        "from": message.get("from", ""),
        "subject": message.get("subject", ""),
        "date": message.get("date", ""),
        "category": category,
        "suggested_action": action,
    }
    items.append(record)
    counts[category] += 1
    if category == "priority":
        priority_items.append({"from": record["from"], "subject": record["subject"], "date": record["date"]})

print(
    json.dumps(
        {
            "total_unread": len(messages),
            "priority": counts["priority"],
            "routine": counts["routine"],
            "deferred": counts["defer"],
            "priority_items": priority_items,
            "items": items,
        },
        indent=2,
    )
)
PY
