---
name: portfolio-pulse
description: Daily portfolio watcher for equities and crypto performance.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📈"
    requires:
      bins: ["curl", "jq", "python3"]
      env: ["PORTFOLIO_FILE", "TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["finance", "portfolio", "alerts", "analytics"]
---

# portfolio-pulse

## Purpose

Pull live price data from Yahoo Finance (equities) and CoinGecko (crypto),
compute daily and running P&L against your cost-basis, and send a digest to
Telegram. No brokerage credentials required — prices only, no trade execution.

`PORTFOLIO_FILE` is a local JSON file you maintain describing your holdings (see
output format section). Cost-basis data never leaves your machine.

## Runbook

1. **Pre-flight** — verify `curl`, `jq`, and `python3` are available.  
   Confirm `PORTFOLIO_FILE` exists and is valid JSON.  
   Confirm `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are set (or accept
   stdout-only fallback).

2. **Fetch prices** — run `scripts/fetch-prices.sh`:
   - Reads tickers from `PORTFOLIO_FILE`
   - Fetches equities via Yahoo Finance query API (`query2.finance.yahoo.com`)
   - Fetches crypto by CoinGecko ID via `api.coingecko.com/api/v3/simple/price`
   - Writes `~/.portfolio-pulse/prices_<date>.json` as a local cache
   - Rate-limit: max one fetch per symbol per 15 minutes (cached)

3. **Calculate P&L** — run `scripts/calc-pnl.sh`:
   - Reads current prices from today's cache
   - Computes day change (%), portfolio day P&L, and total unrealised P&L
   - Flags any position with day change > ±5% as an alert

4. **Generate digest** — `scripts/calc-pnl.sh` prints a formatted digest to
   stdout. If Telegram credentials are set, it sends the digest via Bot API.

5. **Alert threshold** — set `ALERT_THRESHOLD_PCT` (default: `5`) to control
   when individual positions trigger an alert emoji in the digest.

## Stop conditions

1. Abort if `PORTFOLIO_FILE` is missing or not valid JSON.
2. Abort if `curl` is unavailable — no price data can be fetched.
3. Never execute any buy/sell/trade API; this skill is read-only.
4. Respect the Yahoo Finance and CoinGecko public API terms; do not bypass
   rate limits with parallel requests.
5. Do not store raw portfolio data (cost basis, quantities) in any cloud service.

## Output format

### `PORTFOLIO_FILE` (user-maintained JSON)
```json
{
  "equities": [
    {"ticker": "AAPL", "shares": 10, "cost_basis": 150.00},
    {"ticker": "INFY.NS", "shares": 50, "cost_basis": 1400.00}
  ],
  "crypto": [
    {"id": "bitcoin", "symbol": "BTC", "units": 0.05, "cost_basis": 40000},
    {"id": "ethereum", "symbol": "ETH", "units": 0.5, "cost_basis": 2200}
  ]
}
```

### Price cache (`prices_2026-04-22.json`)
```json
{
  "AAPL":  {"price": 172.30, "day_change_pct": 1.2},
  "bitcoin": {"price": 63400, "day_change_pct": -2.1}
}
```

### Daily digest (stdout / Telegram)
```
📈 portfolio-pulse  —  2026-04-22 16:30 IST

Equities
  AAPL     $172.30  +1.2%   P&L today: +$21.70
  INFY.NS  ₹1452.00 +3.7%  ⚠️ P&L today: +₹2,600

Crypto
  BTC      $63,400  -2.1%   P&L today: -$66.50
  ETH      $2,980   +0.8%   P&L today: +$39.00

Portfolio day P&L : +$2,594.20
Total unrealised  : +$8,140.30
```

## Example invocations

- `scripts/fetch-prices.sh` — fetch and cache current prices
- `scripts/calc-pnl.sh` — compute P&L and print digest
- "What is my portfolio doing today?"
- "Alert me if any position moves more than 5% today."
- "What's the Bitcoin price right now?"
