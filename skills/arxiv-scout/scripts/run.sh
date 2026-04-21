#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

MEMORY_PATH="${MEMORY_PATH:?Set MEMORY_PATH to a writable markdown file.}"
export MEMORY_PATH

result="$("$SCRIPT_DIR/fetch.sh" | "$SCRIPT_DIR/sync-notes.sh")"
echo "$result"

new_count="$(printf '%s' "$result" | python3 -c 'import json,sys; print(json.load(sys.stdin)["new"])')"
skipped_count="$(printf '%s' "$result" | python3 -c 'import json,sys; print(json.load(sys.stdin)["skipped"])')"

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  msg="arxiv-scout: ${new_count} new paper(s) added to ${MEMORY_PATH}; ${skipped_count} duplicate(s) skipped"
  if ! curl --silent --show-error --fail -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${msg}" >/dev/null; then
    echo "arxiv-scout: Telegram notification failed; continuing without alert." >&2
  fi
fi
