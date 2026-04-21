#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "invoice-ledger requires python3." >&2
  exit 1
fi

echo "invoice-ledger dependencies look available."
