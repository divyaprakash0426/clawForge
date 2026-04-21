#!/usr/bin/env bash
set -euo pipefail

"$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/report.sh"
