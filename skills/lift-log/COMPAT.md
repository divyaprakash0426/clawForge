# Compatibility notes for lift-log

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | SQLite3 via Python stdlib; no additional packages. All scripts functional. |
| ZeroClaw | full | `python3` and `sqlite3` are available in the standard ZeroClaw image. Telegram PR alerts work via `curl`. |
| PicoClaw | partial | Works on Raspberry Pi 4+. SQLite performance is adequate for personal log sizes (< 50 k rows). Telegram alerts optional — disable if network is intermittent. |
| NullClaw | unsupported | No shell execution. Refer to the SKILL.md runbook for manual tracking guidance. |
| NanoBot | full | Python-native. All scripts run without modification. Ideal for ML-driven volume analytics extensions. |
| IronClaw | partial | `~/.lift-log/` must be added to the IronClaw writable-paths allowlist. Telegram outbound HTTPS must be permitted in the network policy. |

