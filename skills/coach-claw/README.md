# coach-claw 🏸

> Badminton training planner with tournament and recovery context.

## What it does

`coach-claw` keeps a local JSONL log of every badminton session you play —
opponent, match type, duration, intensity, and score. It computes a daily load
score, surfaces upcoming tournaments from a user-maintained fixture list, and
optionally sends a weekly training digest to Telegram.

Designed to pair with `recovery-ai`: coach-claw's load score is the primary
input for tomorrow's recovery recommendation.

## Setup

```bash
# One-time install (creates ~/.coach-claw/ and checks deps)
bash skills/coach-claw/install.sh

# Required env vars (add to ~/.bashrc or equivalent)
export TELEGRAM_BOT_TOKEN="your-bot-token"   # optional — stdout fallback if unset
export TELEGRAM_CHAT_ID="your-chat-id"       # optional
```

## Quickstart

```bash
# Log a session after today's game
bash skills/coach-claw/scripts/log-session.sh

# See this week's training summary
bash skills/coach-claw/scripts/weekly-summary.sh

# Check upcoming tournaments
bash skills/coach-claw/scripts/check-tournaments.sh
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and step-by-step runbook |
| `COMPAT.md` | Per-variant notes — read before enabling on PicoClaw/IronClaw |
| `install.sh` | One-time dependency check and directory setup |
| `scripts/log-session.sh` | Interactive session logger |
| `scripts/weekly-summary.sh` | Aggregate last 7 days and optionally push to Telegram |
| `scripts/check-tournaments.sh` | Display upcoming fixtures with days-until and prep phase |

## Data storage

All data is stored in `~/.coach-claw/sessions.jsonl`. No external database.
Tournament fixture data lives in `~/.coach-claw/tournaments.json` — edit it
directly to add state/district events.

## Security tier: L2

Reads and writes local files. Sends outbound HTTP only to the Telegram Bot API
when credentials are configured. No inbound listeners.

## Pairing

| Skill | How they connect |
|-------|-----------------|
| `recovery-ai` | Reads coach-claw's load score to recommend rest vs. active recovery |
| `lift-log` | Cross-training volume can be fed into the combined load calculation |

