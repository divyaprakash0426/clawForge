# Compatibility notes for coach-claw

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | All scripts run natively. Telegram digest works via `curl`. |
| ZeroClaw | full | `curl` and `jq` are standard in the ZeroClaw runtime image. Session logging and weekly summaries work as-is. |
| PicoClaw | partial | Scripts work on Raspberry Pi 4+. Telegram push may be slow on RPi Zero — disable with unset `TELEGRAM_BOT_TOKEN` to use stdout only. |
| NullClaw | unsupported | No shell execution. Use `SKILL.md` runbook steps as a manual reference only. |
| NanoBot | full | Python-native environment; `python3` dependency is natively satisfied. All scripts functional. |
| IronClaw | partial | Sandboxed filesystem — `~/.coach-claw/` must be whitelisted in the IronClaw permissions manifest. Telegram outbound call requires network permission. |

