#!/usr/bin/env bash
# shorts-forge entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎬 shorts-forge"
echo ""

case "${1:-help}" in
  validate) shift; bash "$SCRIPT_DIR/validate-script.sh" "$@" ;;
  render)   shift; bash "$SCRIPT_DIR/render.sh" "$@" ;;
  *)
    echo "Usage: run.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  validate <script.txt>              Validate and segment a script"
    echo "  render <script.json> [audio.mp3]   Render to MP4"
    echo ""
    echo "Example:"
    echo "  run.sh validate myscript.txt"
    echo "  run.sh render script.json voiceover.mp3"
    ;;
esac
