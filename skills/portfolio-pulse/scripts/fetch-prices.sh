#!/usr/bin/env bash
# Fetch current equity and crypto prices; cache to ~/.portfolio-pulse/
set -euo pipefail

PORTFOLIO_FILE="${PORTFOLIO_FILE:-$HOME/.portfolio-pulse/portfolio.json}"
CACHE_DIR="$HOME/.portfolio-pulse"
DATE=$(date +%Y-%m-%d)
CACHE_FILE="$CACHE_DIR/prices_${DATE}.json"

if [[ ! -f "$PORTFOLIO_FILE" ]]; then
  echo "❌ PORTFOLIO_FILE not found: $PORTFOLIO_FILE"
  echo "   Run install.sh to create a sample portfolio."
  exit 1
fi

command -v curl &>/dev/null || { echo "❌ curl not found."; exit 1; }
command -v jq   &>/dev/null || { echo "❌ jq not found."; exit 1; }

mkdir -p "$CACHE_DIR"

echo "📈 portfolio-pulse — fetching prices ($DATE)"

python3 - "$PORTFOLIO_FILE" "$CACHE_FILE" << 'PYEOF'
import json, sys, os, time, subprocess, urllib.request, urllib.parse

portfolio_file = sys.argv[1]
cache_file     = sys.argv[2]

with open(portfolio_file) as f:
    portfolio = json.load(f)

# Load existing cache to avoid re-fetching within 15 min
existing = {}
if os.path.isfile(cache_file):
    mtime = os.path.getmtime(cache_file)
    if time.time() - mtime < 900:  # 15 min
        print(f"  ℹ️  Using cached prices (< 15 min old): {cache_file}")
        sys.exit(0)

prices = {}

# ── Equities via Yahoo Finance ────────────────────────────────────────────────
equities = portfolio.get("equities", [])
for eq in equities:
    ticker = eq["ticker"]
    try:
        url = f"https://query2.finance.yahoo.com/v8/finance/chart/{urllib.parse.quote(ticker)}?interval=1d&range=2d"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        result = data["chart"]["result"][0]
        meta = result["meta"]
        price = meta.get("regularMarketPrice", 0)
        prev  = meta.get("previousClose", price)
        day_chg = ((price - prev) / prev * 100) if prev else 0
        prices[ticker] = {"price": round(price, 4), "day_change_pct": round(day_chg, 2)}
        print(f"  ✅ {ticker}: {price}  ({day_chg:+.2f}%)")
    except Exception as ex:
        print(f"  ⚠️  {ticker}: fetch failed ({ex})")
        prices[ticker] = {"price": None, "day_change_pct": None}
    time.sleep(0.5)  # be polite

# ── Crypto via CoinGecko ─────────────────────────────────────────────────────
crypto = portfolio.get("crypto", [])
if crypto:
    ids = ",".join(c["id"] for c in crypto)
    try:
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={ids}&vs_currencies=usd&include_24hr_change=true"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        for c in crypto:
            coin_id = c["id"]
            symbol  = c["symbol"]
            info    = data.get(coin_id, {})
            price   = info.get("usd")
            chg     = info.get("usd_24h_change")
            prices[coin_id] = {"price": price, "day_change_pct": round(chg, 2) if chg else None, "symbol": symbol}
            print(f"  ✅ {symbol} ({coin_id}): ${price}  ({chg:+.2f}%)" if price else f"  ⚠️  {symbol}: no data")
    except Exception as ex:
        print(f"  ⚠️  Crypto fetch failed: {ex}")
        for c in crypto:
            prices[c["id"]] = {"price": None, "day_change_pct": None, "symbol": c["symbol"]}

with open(cache_file, "w") as f:
    json.dump(prices, f, indent=2)

print(f"\n  ✅ Prices cached to: {cache_file}")
PYEOF
