# Compatibility notes for portfolio-pulse

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | `curl`, `jq`, and `python3` are standard. Yahoo Finance and CoinGecko fetches work out of the box. |
| ZeroClaw | full | All dependencies available. Price cache is stored in `~/.portfolio-pulse/` using standard file I/O. |
| PicoClaw | partial | `curl` and `jq` are available on Raspberry Pi. Fetching prices works fine. Python P&L calculation may be slow on RPi Zero but is functional. Disable Telegram push if network is cellular-only to avoid data costs. |
| NullClaw | unsupported | No shell execution. Prices can be fetched manually and P&L calculated using the formulas in SKILL.md. |
| NanoBot | full | Python-native; all calculation logic can be extended with pandas for richer charting. Public API endpoints are reachable from NanoBot hosts. |
| IronClaw | partial | Outbound HTTPS to `query2.finance.yahoo.com` and `api.coingecko.com` must be in the network allowlist. Telegram Bot API endpoint must also be allowed. `PORTFOLIO_FILE` must be in the readable-paths list. |

