#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="${COACH_CLAW_DIR:-$HOME/.coach-claw}"

echo "🏸 coach-claw — setup"

# Check required binaries
MISSING=()
for bin in curl jq python3; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  echo "   Install them and re-run this script."
  exit 1
fi

# Create data directory
mkdir -p "$SKILL_DIR"

# Seed tournaments.json if absent
if [[ ! -f "$SKILL_DIR/tournaments.json" ]]; then
  cat > "$SKILL_DIR/tournaments.json" << 'EOF'
[
  {"name": "State Open Badminton Championships", "date": "2026-06-15", "location": "Nagpur", "level": "state"},
  {"name": "District Doubles Cup",               "date": "2026-07-20", "location": "Nagpur", "level": "district"},
  {"name": "Regional Singles Qualifier",         "date": "2026-08-10", "location": "Pune",   "level": "regional"}
]
EOF
  echo "✅ Created $SKILL_DIR/tournaments.json (seed data — edit to match your schedule)"
fi

# Touch sessions log
touch "$SKILL_DIR/sessions.jsonl"

echo ""
echo "✅ coach-claw is ready."
echo "   Data dir : $SKILL_DIR"
echo "   Sessions : $SKILL_DIR/sessions.jsonl"
echo ""
echo "Optional env vars (add to ~/.bashrc):"
echo "  export TELEGRAM_BOT_TOKEN='your-bot-token'"
echo "  export TELEGRAM_CHAT_ID='your-chat-id'"

