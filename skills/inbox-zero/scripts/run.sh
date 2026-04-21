#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

inbox_json="$("$SCRIPT_DIR/fetch-inbox.sh")"
total_unread="$(printf '%s' "$inbox_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"

if [ "$total_unread" -gt 50 ] && [ "${CONFIRM_LARGE_INBOX:-0}" != "1" ]; then
  echo "inbox-zero: $total_unread unread messages found. Re-run with CONFIRM_LARGE_INBOX=1 to continue." >&2
  exit 1
fi

triage_json="$(printf '%s' "$inbox_json" | "$SCRIPT_DIR/triage.sh")"

TRIAGE_JSON="$triage_json" python3 - <<'PY' >&2
import json
import os
report = json.loads(os.environ["TRIAGE_JSON"])
print(f"inbox-zero: priority={report['priority']} routine={report['routine']} deferred={report['deferred']}")
for item in report.get("priority_items", []):
    print(f"priority: {item['from']} | {item['subject']} | {item['date']}")
PY

printf '%s\n' "$triage_json"
