#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.recovery-ai"

echo "🧘 recovery-ai — setup"

# Check required binaries
MISSING=()
for bin in python3 jq; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  exit 1
fi

mkdir -p "$LOG_DIR"
touch "$LOG_DIR/log.jsonl"

echo ""
echo "✅ recovery-ai is ready."
echo "   Log dir : $LOG_DIR"
echo ""
echo "Required env vars (add to ~/.bashrc):"
echo "  export WORKOUT_LOG_PATH='\$HOME/.lift-log/lifts.db'   # or sessions.jsonl for coach-claw"
echo ""
echo "Optional:"
echo "  export HRV_SOURCE_PATH='\$HOME/hrv_export.csv'  # CSV: date,hrv_ms"

