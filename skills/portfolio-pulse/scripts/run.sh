#!/usr/bin/env bash
# portfolio-pulse entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📈 portfolio-pulse"
echo ""

case "${1:-help}" in
  fetch)  bash "$SCRIPT_DIR/fetch-prices.sh" ;;
  pnl)    bash "$SCRIPT_DIR/calc-pnl.sh" ;;
  digest) bash "$SCRIPT_DIR/fetch-prices.sh" && bash "$SCRIPT_DIR/calc-pnl.sh" ;;
  *)
    echo "Usage: run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  fetch    Fetch and cache current prices"
    echo "  pnl      Compute P&L from cached prices and print digest"
    echo "  digest   Fetch + compute in one step"
    ;;
esac
