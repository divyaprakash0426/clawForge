# lift-log 💪

> Structured workout logger with progressive overload tracking.

## What it does

`lift-log` records every gym set you perform into a local SQLite database and
tracks progressive overload across sessions. When you hit a personal record on
any exercise it logs the PR and optionally fires a Telegram alert. The weekly
summary shows per-muscle-group volume, average RPE, and flags deload signals.

## Setup

```bash
# One-time install (creates ~/.lift-log/lifts.db and checks deps)
bash skills/lift-log/install.sh

# Required env vars
export LOGBOOK_PATH="$HOME/.lift-log/lifts.db"   # default, can be changed

# Optional — for Telegram PR alerts
export TELEGRAM_BOT_TOKEN="your-bot-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

## Quickstart

```bash
# Log today's session (interactive)
bash skills/lift-log/scripts/log-workout.sh

# Check if you hit any PRs today
bash skills/lift-log/scripts/check-prs.sh

# Weekly volume and intensity digest
bash skills/lift-log/scripts/weekly-summary.sh
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and runbook |
| `COMPAT.md` | Per-variant notes |
| `install.sh` | Creates DB directory, verifies python3/sqlite3 |
| `scripts/log-workout.sh` | Interactive set-by-set workout entry |
| `scripts/check-prs.sh` | Compare today's top sets against historical maxima |
| `scripts/weekly-summary.sh` | Volume/intensity digest with progressive overload cues |

## Data storage

SQLite database at `$LOGBOOK_PATH`. Schema: `sets`, `personal_records` tables.
No cloud sync. Back up by copying the `.db` file.

## Security tier: L1

Read/write to local SQLite only. Optional Telegram push for PR events (outbound
HTTPS). No credentials stored in the database.

## Pairing

| Skill | How they connect |
|-------|-----------------|
| `recovery-ai` | Reads lift-log intensity to compute ACWR and recovery recommendations |
| `coach-claw` | Combined load from gym + court sessions for holistic recovery planning |

