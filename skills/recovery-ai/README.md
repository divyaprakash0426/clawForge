# recovery-ai 🧘

> HRV-aware recovery advisor based on rolling 7-day training load.

## What it does

`recovery-ai` reads workout data from `lift-log` or `coach-claw` (or both),
computes the Acute:Chronic Workload Ratio (ACWR), optionally incorporates an
HRV reading from a wearable CSV export, and outputs a recovery recommendation
for the next day: **full rest**, **active recovery**, or **train as planned**.

All computation is local — no wearable account integration, no cloud APIs.

## Setup

```bash
# One-time setup (creates ~/.recovery-ai/ and checks deps)
bash skills/recovery-ai/install.sh

# Required env vars
export WORKOUT_LOG_PATH="$HOME/.lift-log/lifts.db"   # or sessions.jsonl for coach-claw

# Optional — HRV data (CSV: date,hrv_ms or JSONL: {"date":"..","hrv_ms":55})
export HRV_SOURCE_PATH="$HOME/hrv_export.csv"
```

## Quickstart

```bash
# Compute training load (ACWR figures)
bash skills/recovery-ai/scripts/calc-load.sh

# Full recommendation with HRV integration
bash skills/recovery-ai/scripts/recommend.sh
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and detailed runbook |
| `COMPAT.md` | Per-variant notes |
| `install.sh` | Creates log directory, verifies python3 |
| `scripts/calc-load.sh` | Compute acute/chronic load and ACWR |
| `scripts/recommend.sh` | Output full recovery recommendation with contributing factors |

## HRV export formats

The skill accepts two HRV file formats:

- **CSV**: header row `date,hrv_ms`, one row per day  
  `2026-04-22,54`
- **JSONL**: one JSON object per line  
  `{"date":"2026-04-22","hrv_ms":54}`

Most wearables (Garmin, Polar, Whoop) can export CSV. Use the format that matches
your device's export.

## Decision logic (ACWR thresholds)

| ACWR | HRV | Recommendation |
|------|-----|----------------|
| > 1.5 | any | Full rest |
| 1.2–1.5 | suppressed | Full rest |
| 1.2–1.5 | normal | Active recovery |
| < 1.2 | normal / absent | Train as planned |
| < 0.8 | any | Train + detraining warning |

## Security tier: L1

Read-only access to workout logs and HRV files. Writes only to
`~/.recovery-ai/log.jsonl`. No external API calls.

## Pairing

| Skill | How they connect |
|-------|-----------------|
| `lift-log` | Primary workout data source (SQLite) |
| `coach-claw` | Alternative workout data source (JSONL sessions) |

