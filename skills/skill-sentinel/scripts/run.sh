#!/usr/bin/env bash
set -euo pipefail

python3 "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/scan.py" "$@"
