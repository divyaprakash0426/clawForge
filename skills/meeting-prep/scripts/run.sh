#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

: "${MEMORY_PATH:?meeting-prep run: set MEMORY_PATH}"
if [ -d "$MEMORY_PATH" ]; then
  echo "meeting-prep run: MEMORY_PATH is a directory." >&2
  exit 1
fi

event_json="$("$SCRIPT_DIR/next-event.sh")"
if [ "$event_json" = "null" ] || [ -z "$event_json" ]; then
  echo "No upcoming events in the next 24 hours."
  exit 0
fi

keywords="$(EVENT_JSON="$event_json" python3 - <<'PY'
import json
import os
import re

stopwords = {"meeting", "call", "sync", "standup", "1:1", "weekly", "daily"}
event = json.loads(os.environ["EVENT_JSON"])
words = re.findall(r"[A-Za-z0-9#]+", event.get("title", ""))
filtered = [word for word in words if word.lower() not in stopwords]
print(" ".join(filtered or words))
PY
)"

if [ -n "$keywords" ]; then
  # shellcheck disable=SC2206
  keyword_array=($keywords)
else
  keyword_array=()
fi

notes_json="$("$SCRIPT_DIR/retrieve-notes.sh" "${keyword_array[@]}")"
brief="$("$SCRIPT_DIR/brief.sh" <(printf '%s' "$event_json") <(printf '%s' "$notes_json"))"
printf '%s' "$brief"

if [ "${SEND_TO_CHAT:-0}" = "1" ]; then
  : "${CHAT_WEBHOOK:?meeting-prep run: set CHAT_WEBHOOK when SEND_TO_CHAT=1}"
  payload="$(BRIEF_TEXT="$brief" python3 - <<'PY'
import json
import os
print(json.dumps({"text": os.environ["BRIEF_TEXT"]}))
PY
)"
  curl --silent --show-error --fail -X POST -H 'Content-Type: application/json' --data "$payload" "$CHAT_WEBHOOK" >/dev/null
fi
