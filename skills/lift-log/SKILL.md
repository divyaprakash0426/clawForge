---
name: lift-log
description: Structured workout logger with progressive overload tracking.
version: 1.0.0
metadata:
  openclaw:
    emoji: "💪"
    requires:
      bins: ["python3", "jq"]
      env: ["LOGBOOK_PATH"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: ["health", "fitness", "workouts", "tracking"]
---

# lift-log

## Purpose

Log gym workouts, track progressive overload across exercises, and receive
personal-record (PR) alerts. All data is stored locally in a SQLite database at
`$LOGBOOK_PATH` (default: `~/.lift-log/lifts.db`). Optional Telegram push for PR
events requires `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.

## Runbook

1. **Pre-flight** — verify `python3` and `jq` are available.  
   Create `~/.lift-log/` if it does not exist.  
   Set `LOGBOOK_PATH` or accept the default.

2. **Log a session** — run `scripts/log-workout.sh` and answer the prompts:
   - Date (default: today)
   - Exercise name (e.g. `Barbell Squat`)
   - Sets × reps × weight (e.g. `3x5x100kg`)
   - RPE 1–10 (optional)
   - Notes (optional)  
   Each set is inserted as a row in the `sets` table.

3. **Check personal records** — run `scripts/check-prs.sh` to compare today's
   top set for each exercise against the historical maximum. Emit a PR alert row
   in `personal_records` table and optionally push via Telegram.

4. **Weekly summary** — run `scripts/weekly-summary.sh` to print volume
   (sets × reps × kg) and intensity (avg RPE) per muscle group for the last 7
   days. Highlights exercises where week-over-week volume dropped > 20% (deload
   signal).

5. **Progressive overload check** — the summary script checks whether any
   compound lift (squat, deadlift, bench, overhead press, row) has not progressed
   in weight or reps over the last 3 sessions and prints a coaching cue.

## Stop conditions

1. Abort if `python3` is unavailable — SQLite3 is used via the stdlib `sqlite3` module.
2. Abort if `LOGBOOK_PATH` points to a non-writable directory.
3. Do **not** delete or vacuum the database without an explicit `--purge` flag.
4. Telegram PR alerts are best-effort; a send failure must not abort the local log write.
5. Abort for `nullclaw` variant — no shell execution.

## Output format

### Set log row (SQLite `sets` table)
```
id | date       | exercise        | set_num | reps | weight_kg | rpe | notes
 1 | 2026-04-22 | Barbell Squat   |       1 |    5 |      100  |   8 | felt solid
```

### Weekly summary (stdout)
```
💪 lift-log weekly brief  2026-04-15 → 2026-04-21
Sessions     : 4
Total volume : 18,450 kg
Avg RPE      : 7.6

Exercise breakdown:
  Barbell Squat       320 kg × 15 sets  ↑ vs last week
  Bench Press         275 kg × 12 sets  → same
  Deadlift            260 kg × 6 sets   ↓ low volume — check recovery

🏆 New PRs this week:
  Romanian Deadlift: 120 kg × 5 (prev 117.5 kg)
```

## Example invocations

- `scripts/log-workout.sh` — interactive workout entry
- `scripts/check-prs.sh` — detect personal records from today's session
- `scripts/weekly-summary.sh` — print volume and intensity digest
- "Log my bench press session: 4×6×80kg, RPE 8."
- "Did I hit any PRs this week?"
- "Show me my squat progression over the last month."
