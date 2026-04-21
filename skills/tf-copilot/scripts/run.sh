#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/plan.sh" "$@"
"$SCRIPT_DIR/lint.sh"
"$SCRIPT_DIR/report.sh" tf-plan.json tf-findings.json
