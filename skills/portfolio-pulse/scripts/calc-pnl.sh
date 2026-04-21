#!/usr/bin/env bash
# Compute P&L from cached prices and print/push a portfolio digest
set -euo pipefail

PORTFOLIO_FILE="${PORTFOLIO_FILE:-$HOME/.portfolio-pulse/portfolio.json}"
CACHE_DIR="$HOME/.portfolio-pulse"
DATE=$(date +%Y-%m-%d)
CACHE_FILE="$CACHE_DIR/prices_${DATE}.json"
ALERT_THRESHOLD="${ALERT_THRESHOLD_PCT:-5}"

if [[ ! -f "$PORTFOLIO_FILE" ]]; then
  echo "❌ PORTFOLIO_FILE not found: $PORTFOLIO_FILE"
  exit 1
fi

if [[ ! -f "$CACHE_FILE" ]]; then
  echo "❌ Price cache not found for $DATE. Run fetch-prices.sh first."
  exit 1
fi

python3 - "$PORTFOLIO_FILE" "$CACHE_FILE" "$ALERT_THRESHOLD" << 'PYEOF'
import json, sys
from datetime import datetime

portfolio_file = sys.argv[1]
cache_file     = sys.argv[2]
threshold      = float(sys.argv[3])

with open(portfolio_file) as f:
    portfolio = json.load(f)

with open(cache_file) as f:
    prices = json.load(f)

now = datetime.now().strftime("%Y-%m-%d %H:%M")

lines = [f"\n📈 portfolio-pulse  —  {now}\n"]

total_day_pnl   = 0.0
total_unrealised = 0.0

# ── Equities ──────────────────────────────────────────────────────────────────
eq_lines = []
for eq in portfolio.get("equities", []):
    ticker    = eq["ticker"]
    shares    = eq["shares"]
    cost      = eq["cost_basis"]
    info      = prices.get(ticker, {})
    price     = info.get("price")
    day_chg   = info.get("day_change_pct")

    if price is None:
        eq_lines.append(f"  {ticker:<12s} — price unavailable")
        continue

    day_pnl   = shares * price * (day_chg / 100) if day_chg is not None else 0
    unrealised = shares * (price - cost)
    total_day_pnl    += day_pnl
    total_unrealised += unrealised

    alert = " ⚠️" if day_chg is not None and abs(day_chg) >= threshold else ""
    chg_str = f"{day_chg:+.1f}%" if day_chg is not None else "n/a"
    eq_lines.append(f"  {ticker:<12s} {price:>10.2f}  {chg_str:>7s}{alert}   P&L today: {day_pnl:+.2f}")

if eq_lines:
    lines.append("Equities")
    lines.extend(eq_lines)
    lines.append("")

# ── Crypto ────────────────────────────────────────────────────────────────────
crypto_lines = []
for c in portfolio.get("crypto", []):
    coin_id   = c["id"]
    symbol    = c.get("symbol", coin_id.upper())
    units     = c["units"]
    cost      = c["cost_basis"]
    info      = prices.get(coin_id, {})
    price     = info.get("price")
    day_chg   = info.get("day_change_pct")

    if price is None:
        crypto_lines.append(f"  {symbol:<12s} — price unavailable")
        continue

    day_pnl    = units * price * (day_chg / 100) if day_chg is not None else 0
    unrealised = units * (price - cost)
    total_day_pnl    += day_pnl
    total_unrealised += unrealised

    alert = " ⚠️" if day_chg is not None and abs(day_chg) >= threshold else ""
    chg_str = f"{day_chg:+.1f}%" if day_chg is not None else "n/a"
    crypto_lines.append(f"  {symbol:<12s} ${price:>10,.0f}  {chg_str:>7s}{alert}   P&L today: {day_pnl:+.2f}")

if crypto_lines:
    lines.append("Crypto")
    lines.extend(crypto_lines)
    lines.append("")

lines.append(f"Portfolio day P&L : {total_day_pnl:+,.2f}")
lines.append(f"Total unrealised  : {total_unrealised:+,.2f}")
lines.append("")

output = "\n".join(lines)
print(output)

# Write to module-level for Telegram push
import os
os.environ["_PP_OUTPUT"] = output
PYEOF

# Optional Telegram push
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  DIGEST=$(python3 - "$PORTFOLIO_FILE" "$CACHE_FILE" "$ALERT_THRESHOLD" 2>/dev/null << 'PYEOF'
import json, sys
from datetime import datetime

portfolio_file = sys.argv[1]
cache_file     = sys.argv[2]
threshold      = float(sys.argv[3])

with open(portfolio_file) as f: portfolio = json.load(f)
with open(cache_file) as f:     prices    = json.load(f)

parts = [f"📈 portfolio-pulse {datetime.now().strftime('%Y-%m-%d %H:%M')}"]
for eq in portfolio.get("equities", []):
    info = prices.get(eq["ticker"], {})
    if info.get("price"):
        chg = info.get("day_change_pct", 0)
        parts.append(f"{eq['ticker']}: {info['price']:.2f} ({chg:+.1f}%)")
for c in portfolio.get("crypto", []):
    info = prices.get(c["id"], {})
    if info.get("price"):
        chg = info.get("day_change_pct", 0)
        parts.append(f"{c['symbol']}: ${info['price']:,.0f} ({chg:+.1f}%)")
print("\n".join(parts))
PYEOF
  )
  curl -s -o /dev/null -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${DIGEST}" || true
fi
