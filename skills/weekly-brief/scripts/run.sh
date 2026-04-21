#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

git_json="$("$SCRIPT_DIR/git-digest.sh")"
pr_json="$("$SCRIPT_DIR/pr-digest.sh")"
logbook_json="$("$SCRIPT_DIR/logbook-digest.sh")"

brief="$("$SCRIPT_DIR/assemble.sh" <(printf '%s' "$git_json") <(printf '%s' "$pr_json") <(printf '%s' "$logbook_json"))"
printf '%s\n' "$brief"

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  telegram_text="$(printf '%s' "$brief" | python3 -c 'import sys; text=sys.stdin.read(); print(text[:3500] + ("\n…" if len(text) > 3500 else ""))')"
  if ! curl --silent --show-error --fail -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${telegram_text}" >/dev/null; then
    echo "weekly-brief: Telegram delivery failed; brief was still printed locally." >&2
  fi
fi
