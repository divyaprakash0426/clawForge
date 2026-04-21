#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)"

if [ "$#" -gt 0 ]; then
  python3 "$SCRIPT_DIR/inspect.py" "$@"
  exit 0
fi

echo "Installed skills under $REPO_ROOT/skills:"
find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d -printf -- '- %f
' | sort
