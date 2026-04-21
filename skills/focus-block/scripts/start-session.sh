#!/usr/bin/env bash
set -euo pipefail

JOURNAL_PATH="${JOURNAL_PATH:-$HOME/notes/focus-log.md}"
task_description="${*:-${FOCUS_TASK:-}}"

if [ -z "$task_description" ]; then
  echo "focus-block start: provide a task description." >&2
  exit 1
fi
if [ -d "$JOURNAL_PATH" ]; then
  echo "focus-block start: JOURNAL_PATH is a directory: $JOURNAL_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$JOURNAL_PATH")"
touch "$JOURNAL_PATH"

if grep -q '^- status: open$' "$JOURNAL_PATH"; then
  echo "focus-block start: an open session already exists. Close it before starting another." >&2
  exit 1
fi

session_id="$(python3 - <<'PY'
import datetime as dt
import random
print(dt.datetime.now().strftime('%Y%m%d') + '-' + format(random.randint(0, 0xFFFF), '04x'))
PY
)"
start_time="$(date -Iseconds)"

dnd_disabled="false"
if command -v gsettings >/dev/null 2>&1; then
  current_state="$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null || printf 'unsupported')"
  if [ "$current_state" = "true" ]; then
    if gsettings set org.gnome.desktop.notifications show-banners false 2>/dev/null; then
      dnd_disabled="true"
    else
      echo "focus-block start: could not disable GNOME notifications; continuing." >&2
    fi
  fi
else
  echo "focus-block start: DND integration unavailable on this host; continuing." >&2
fi

cat >> "$JOURNAL_PATH" <<EOF

## Focus Session $session_id
- task: $task_description
- start: $start_time
- end: pending
- duration_minutes: pending
- status: open
- dnd_disabled: $dnd_disabled
EOF

cat <<EOF
Started focus session $session_id
Task: $task_description
Reminder: work for 25 minutes, then run end-session.sh to close the block.
EOF
