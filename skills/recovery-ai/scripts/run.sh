#!/usr/bin/env bash
# recovery-ai entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧘 recovery-ai"
echo ""

case "${1:-help}" in
  load)      bash "$SCRIPT_DIR/calc-load.sh" ;;
  recommend) bash "$SCRIPT_DIR/recommend.sh" ;;
  *)
    echo "Usage: run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  load        Show ACWR and training load figures"
    echo "  recommend   Full recovery recommendation with contributing factors"
    ;;
esac
