#!/usr/bin/env bash
set -euo pipefail

if [ "${CLAW_VARIANT:-}" = "ironclaw" ] && [ -z "${MOCK_MODE:-}" ]; then
  export MOCK_MODE=1
fi

if [ "${MOCK_MODE:-0}" = "1" ]; then
  cat <<'EOF'
[
  {
    "from": "boss@company.com",
    "subject": "Action required: Q3 report",
    "date": "2024-06-15",
    "message_id": "<boss-q3@example.com>"
  },
  {
    "from": "newsletter@example.com",
    "subject": "Weekly engineering digest",
    "date": "2024-06-14",
    "message_id": "<newsletter@example.com>"
  },
  {
    "from": "finance@example.com",
    "subject": "Invoice due this Friday",
    "date": "2024-06-13",
    "message_id": "<invoice@example.com>"
  }
]
EOF
  exit 0
fi

: "${IMAP_HOST:?inbox-zero fetch: set IMAP_HOST}"
: "${IMAP_USER:?inbox-zero fetch: set IMAP_USER}"
: "${IMAP_PASS:?inbox-zero fetch: set IMAP_PASS}"

mailbox="${IMAP_MAILBOX:-INBOX}"
protocol="${IMAP_PROTOCOL:-imaps}"
auth_target="${protocol}://${IMAP_HOST}/${mailbox}"

if ! search_response="$(curl --silent --show-error --fail --url "$auth_target" --user "${IMAP_USER}:${IMAP_PASS}" -X 'SEARCH UNSEEN')"; then
  echo "inbox-zero fetch: IMAP authentication or connection failed." >&2
  exit 1
fi

message_ids="$(SEARCH_RESPONSE="$search_response" python3 - <<'PY'
import os
import re
response = os.environ.get("SEARCH_RESPONSE", "")
match = re.search(r'\* SEARCH\s*(.*)', response)
if not match or not match.group(1).strip():
    print("")
else:
    print(" ".join(part for part in match.group(1).split() if part.isdigit()))
PY
)"

if [ -z "$message_ids" ]; then
  printf '[]\n'
  exit 0
fi

inbox_json="$(message_ids="$message_ids" mailbox="$mailbox" protocol="$protocol" IMAP_HOST="$IMAP_HOST" IMAP_USER="$IMAP_USER" IMAP_PASS="$IMAP_PASS" python3 - <<'PY'
import email
import json
import os
import subprocess

ids = [item for item in os.environ["message_ids"].split() if item]
protocol = os.environ["protocol"]
host = os.environ["IMAP_HOST"]
mailbox = os.environ["mailbox"]
user = os.environ["IMAP_USER"]
password = os.environ["IMAP_PASS"]
items = []

for seq in ids:
    target = f"{protocol}://{host}/{mailbox}"
    command = [
        "curl", "--silent", "--show-error", "--fail",
        "--url", target,
        "--user", f"{user}:{password}",
        "-X", f"FETCH {seq} BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE MESSAGE-ID)]",
    ]
    completed = subprocess.run(command, capture_output=True, text=True)
    if completed.returncode != 0:
        raise SystemExit(f"inbox-zero fetch: failed to fetch headers for message {seq}: {completed.stderr.strip()}")
    raw = completed.stdout
    header_lines = []
    capture = False
    for line in raw.splitlines():
        if "BODY[HEADER.FIELDS" in line:
            capture = True
            continue
        if capture and line.strip() == ")":
            break
        if capture:
            header_lines.append(line)
    parsed = email.message_from_string("\n".join(header_lines))
    items.append(
        {
            "from": parsed.get("From", "Unknown sender"),
            "subject": parsed.get("Subject", "(no subject)"),
            "date": parsed.get("Date", ""),
            "message_id": parsed.get("Message-ID", f"<imap-{seq}@local>"),
        }
    )

print(json.dumps(items, indent=2))
PY
)"

printf '%s\n' "$inbox_json"
