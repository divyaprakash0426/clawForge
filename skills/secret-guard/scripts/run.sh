#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-.}"

"$SCRIPT_DIR/scan.sh" "$target"
"$SCRIPT_DIR/report.sh" secret-findings.json
