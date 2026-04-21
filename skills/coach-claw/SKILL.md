---
name: coach-claw
description: Badminton training planner with tournament and recovery context.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🏸"
    requires:
      bins: ["curl", "jq", "python3"]
      env: ["TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["health", "badminton", "training", "recovery"]
---

# coach-claw

## Purpose

Log badminton sessions, track your tournament roadmap, and surface recovery
recommendations that account for Hatha Yoga schedule cross-training.  
Reads your local session log (`~/.coach-claw/sessions.jsonl`) and writes
structured JSON summaries. No data ever leaves your machine unless you opt in to
the Telegram digest.

## Runbook

1. **Pre-flight** — confirm `curl`, `jq`, and `python3` are in `PATH`.  
   If `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` are unset, digests are printed to
   stdout only (non-fatal).

2. **Log a session** — run `scripts/log-session.sh` and answer the prompts:
   - Date (default: today `YYYY-MM-DD`)
   - Opponent name or "solo drill"
   - Match type: `singles` | `doubles` | `drill`
   - Duration in minutes
   - Intensity: `low` | `medium` | `high`
   - Score (optional, e.g. `21-18 21-15`)
   - Notes (optional free text)  
   Output: one JSON line appended to `~/.coach-claw/sessions.jsonl`.

3. **Weekly summary** — run `scripts/weekly-summary.sh` to aggregate the last 7
   days: total court time, intensity distribution, win/loss, and a recovery load
   score (1–10) fed to `recovery-ai` if installed.

4. **Tournament check** — run `scripts/check-tournaments.sh` to display the
   upcoming schedule loaded from `~/.coach-claw/tournaments.json`. Edit that file
   to add state/district fixtures you want tracked; the script annotates each event
   with days-until and recommended prep-phase label.

5. **Telegram digest** — the weekly summary script calls the Telegram Bot API
   (send-message) if credentials are present. No webhooks or inbound listeners.
   Abort this step if the token is absent; stdout fallback is always safe.

## Stop conditions

1. Abort if `python3` or `jq` is missing — required for JSON manipulation.
2. Abort if the active variant is `nullclaw` — no shell execution available.
3. Do **not** overwrite `sessions.jsonl` in bulk without an explicit `--reset` flag.
4. Never transmit session data to any third-party service (only Telegram Bot API).
5. Abort the Telegram send if `TELEGRAM_BOT_TOKEN` is not set; fall back to stdout.

## Output format

### Session log entry (`sessions.jsonl`)
```json
{
  "date": "2026-04-22",
  "opponent": "Rahul",
  "type": "singles",
  "duration_min": 75,
  "intensity": "high",
  "score": "21-18 18-21 21-17",
  "notes": "Served well; backhand net shots inconsistent",
  "load_score": 8
}
```

### Weekly summary (stdout / Telegram)
```
🏸 coach-claw weekly brief  2026-04-14 → 2026-04-20
Court time : 3 h 45 min  (3 sessions)
Intensity  : low 1 · medium 1 · high 1
Win/loss   : 4–2
Load score : 7.2 / 10  ⚠ consider active-recovery day tomorrow
Yoga days  : 2  (Mon, Thu)
Next tournament : State Open — 14 days away  (prep phase: peaking)
```

## Example invocations

- `scripts/log-session.sh` — interactive session logger
- `scripts/weekly-summary.sh` — print this week's training recap
- `scripts/check-tournaments.sh` — list upcoming tournaments with days-until
- "Log today's badminton session and tell me my load score."
- "How many court hours did I put in this month?"
- "What tournaments are coming up in the next 30 days?"
