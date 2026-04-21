#!/usr/bin/env bash
# expense-log entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "💰 expense-log"
echo ""

case "${1:-help}" in
  import)     shift; bash "$SCRIPT_DIR/import-csv.sh" "$@" ;;
  categorize) bash "$SCRIPT_DIR/categorize.sh" ;;
  report)     shift; bash "$SCRIPT_DIR/report.sh" "$@" ;;
  *)
    echo "Usage: run.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  import [--file <path>|--dir <dir>]   Import bank CSV or SMS export"
    echo "  categorize                            Apply keyword rules to uncategorised rows"
    echo "  report [--month YYYY-MM] [--trend N]  Generate spend report"
    ;;
esac
