#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/audit.sh" > docker-audit.json
"$SCRIPT_DIR/report.sh" docker-audit.json
