#!/usr/bin/env bash
# lift-log entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "💪 lift-log"
echo ""

case "${1:-help}" in
  log)     bash "$SCRIPT_DIR/log-workout.sh" ;;
  prs)     bash "$SCRIPT_DIR/check-prs.sh" ;;
  summary) bash "$SCRIPT_DIR/weekly-summary.sh" ;;
  *)
    echo "Usage: run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  log       Log a new workout session"
    echo "  prs       Check personal records from today's session"
    echo "  summary   Print weekly volume and intensity digest"
    ;;
esac
