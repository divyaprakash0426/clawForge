#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.portfolio-pulse"
PORTFOLIO_FILE="${PORTFOLIO_FILE:-$CACHE_DIR/portfolio.json}"

echo "📈 portfolio-pulse — setup"

# Check required binaries
MISSING=()
for bin in curl jq python3; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  exit 1
fi

mkdir -p "$CACHE_DIR"

# Seed sample portfolio if none exists
if [[ ! -f "$PORTFOLIO_FILE" ]]; then
  cat > "$PORTFOLIO_FILE" << 'EOF'
{
  "equities": [
    {"ticker": "AAPL",    "shares": 10,   "cost_basis": 150.00},
    {"ticker": "INFY.NS", "shares": 50,   "cost_basis": 1400.00}
  ],
  "crypto": [
    {"id": "bitcoin",  "symbol": "BTC", "units": 0.01, "cost_basis": 40000},
    {"id": "ethereum", "symbol": "ETH", "units": 0.1,  "cost_basis": 2200}
  ]
}
EOF
  echo "✅ Created sample portfolio at $PORTFOLIO_FILE"
  echo "   Edit it to reflect your actual holdings and cost basis."
fi

# Check Telegram credentials (informational)
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "ℹ️  TELEGRAM_BOT_TOKEN not set — digest will print to stdout only."
fi

echo ""
echo "✅ portfolio-pulse is ready."
echo "   Cache dir      : $CACHE_DIR"
echo "   Portfolio file : $PORTFOLIO_FILE"
echo ""
echo "Required env vars:"
echo "  export PORTFOLIO_FILE='$PORTFOLIO_FILE'"
echo "  export TELEGRAM_BOT_TOKEN='your-bot-token'"
echo "  export TELEGRAM_CHAT_ID='your-chat-id'"
echo ""
echo "Optional:"
echo "  export ALERT_THRESHOLD_PCT=5   # default: 5%"

