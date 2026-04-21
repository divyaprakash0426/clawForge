#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command="${1:-status}"

case "$command" in
  start)
    shift
    "$SCRIPT_DIR/start-session.sh" "$@"
    ;;
  end)
    shift
    "$SCRIPT_DIR/end-session.sh" "$@"
    ;;
  status)
    shift
    "$SCRIPT_DIR/status.sh" "$@"
    ;;
  *)
    "$SCRIPT_DIR/start-session.sh" "$command" "$@"
    ;;
esac
