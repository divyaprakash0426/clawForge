#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in curl jq python3; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "inbox-zero: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

: "${IMAP_HOST:?inbox-zero: set IMAP_HOST}"
: "${IMAP_USER:?inbox-zero: set IMAP_USER}"
: "${IMAP_PASS:?inbox-zero: set IMAP_PASS}"

echo "inbox-zero: IMAP configuration present. Password intentionally not echoed."
