# portfolio-pulse 📈

> Daily P&L digest for equities and crypto — no brokerage credentials needed.

## What it does

`portfolio-pulse` fetches current prices from Yahoo Finance (equities) and
CoinGecko (crypto), computes daily and total unrealised P&L against your local
cost-basis file, and sends a formatted digest to Telegram. No trade execution,
no brokerage API — prices only.

## Setup

```bash
# One-time install (creates ~/.portfolio-pulse/, checks deps)
bash skills/portfolio-pulse/install.sh

# Required env vars
export PORTFOLIO_FILE="$HOME/.portfolio-pulse/portfolio.json"
export TELEGRAM_BOT_TOKEN="your-bot-token"
export TELEGRAM_CHAT_ID="your-chat-id"

# Optional — alert threshold (default: 5%)
export ALERT_THRESHOLD_PCT=5
```

## Portfolio file

Create `~/.portfolio-pulse/portfolio.json`:

```json
{
  "equities": [
    {"ticker": "AAPL",    "shares": 10,   "cost_basis": 150.00},
    {"ticker": "INFY.NS", "shares": 50,   "cost_basis": 1400.00}
  ],
  "crypto": [
    {"id": "bitcoin",  "symbol": "BTC", "units": 0.05, "cost_basis": 40000},
    {"id": "ethereum", "symbol": "ETH", "units": 0.5,  "cost_basis": 2200}
  ]
}
```

## Quickstart

```bash
# Fetch and cache current prices
bash skills/portfolio-pulse/scripts/fetch-prices.sh

# Compute P&L and print/send digest
bash skills/portfolio-pulse/scripts/calc-pnl.sh
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and runbook |
| `COMPAT.md` | Per-variant notes |
| `install.sh` | Check deps, create config and cache directories |
| `scripts/fetch-prices.sh` | Pull prices from Yahoo Finance + CoinGecko; write daily cache |
| `scripts/calc-pnl.sh` | Read cached prices, compute P&L, print/Telegram digest |

## Rate limiting

- Yahoo Finance: 1 request per symbol per 15 min (cached locally)
- CoinGecko free tier: 10–30 req/min — fetch-prices.sh respects this

## Security tier: L2

Cost-basis data stays in `PORTFOLIO_FILE` on your machine. Outbound HTTPS to
Yahoo Finance and CoinGecko (public APIs, no auth). Telegram Bot API for push
notifications. No trading or order placement, ever.

