#!/usr/bin/env bash
# coach-claw entrypoint — log a session, update weekly summary, check tournaments
set -euo pipefail

SKILL_DIR="$HOME/.coach-claw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🏸 coach-claw"
echo ""

case "${1:-help}" in
  log)       bash "$SCRIPT_DIR/log-session.sh" ;;
  summary)   bash "$SCRIPT_DIR/weekly-summary.sh" ;;
  tournaments) bash "$SCRIPT_DIR/check-tournaments.sh" ;;
  *)
    echo "Usage: run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  log           Log a new badminton session"
    echo "  summary       Print weekly training summary"
    echo "  tournaments   List upcoming tournaments"
    ;;
esac
