---
name: recovery-ai
description: Rolling-load recovery guidance driven by workout and HRV signals.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🧘"
    requires:
      bins: ["python3", "jq"]
      env: ["HRV_SOURCE_PATH", "WORKOUT_LOG_PATH"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: ["health", "recovery", "hrv", "training"]
---

# recovery-ai

## Purpose

Analyse the rolling 7-day training load from `lift-log` or `coach-claw` session
logs alongside optional Heart Rate Variability (HRV) readings to recommend one
of three recovery states for tomorrow:

- **Full rest** — complete day off from structured exercise  
- **Active recovery** — 20–40 min low-intensity walk/swim/yoga  
- **Train as planned** — load is sustainable, proceed normally  

All processing is local. No data leaves the device.

## Runbook

1. **Pre-flight** — verify `python3` and `jq` are in `PATH`.  
   - `WORKOUT_LOG_PATH` must point to either `lift-log`'s `lifts.db` or
     `coach-claw`'s `sessions.jsonl`; both formats are auto-detected.  
   - `HRV_SOURCE_PATH` is optional. Accepted formats:
     - CSV with columns `date,hrv_ms` exported from a wearable
     - JSONL with `{"date":"YYYY-MM-DD","hrv_ms":55}` entries
     If absent, load-only scoring is used (accuracy reduced).

2. **Calculate training load** — run `scripts/calc-load.sh`:
   - Reads the last 7 days of workout intensity from `WORKOUT_LOG_PATH`.
   - Computes Acute (7-day) and Chronic (28-day) Training Load.
   - Derives Acute:Chronic Workload Ratio (ACWR).

3. **HRV delta** — if `HRV_SOURCE_PATH` is set, compare today's HRV against the
   30-day rolling baseline. A drop of >10% is a suppression signal.

4. **Recommend** — run `scripts/recommend.sh`:
   - ACWR > 1.5 → **Full rest** regardless of HRV.
   - ACWR 1.2–1.5 **and** HRV suppressed → **Full rest**.
   - ACWR 1.2–1.5 **and** HRV normal → **Active recovery**.
   - ACWR < 1.2 **and** HRV normal (or absent) → **Train as planned**.
   - ACWR < 0.8 → **Train as planned** + note that detraining risk is rising.

5. **Output** — print recommendation plus contributing factors to stdout.  
   Optionally append a JSON summary to `~/.recovery-ai/log.jsonl`.

## Stop conditions

1. Abort if `WORKOUT_LOG_PATH` is unset or the file does not exist.
2. Abort if fewer than 3 days of workout data are present — insufficient for ACWR.
3. Never modify the source workout log or HRV file.
4. Abort for `nullclaw` variant — no shell execution.

## Output format

### Recommendation (stdout)
```
🧘 recovery-ai  —  2026-04-23

Training load (7-day acute)  : 420 AU
Training load (28-day chronic): 310 AU
ACWR                         : 1.35
HRV today                    : 48 ms  (baseline 55 ms  ↓ 12.7%)

⚠️  Recommendation: ACTIVE RECOVERY
    Reason: Elevated workload ratio + HRV suppression.
    Suggestion: 30 min easy walk or Hatha Yoga flow — no high-intensity.
```

### Log entry (`~/.recovery-ai/log.jsonl`)
```json
{
  "date": "2026-04-23",
  "acwr": 1.35,
  "hrv_ms": 48,
  "hrv_baseline_ms": 55,
  "recommendation": "active_recovery",
  "reason": "elevated_acwr+hrv_suppressed"
}
```

## Example invocations

- `scripts/calc-load.sh` — print ACWR and load figures
- `scripts/recommend.sh` — print full recovery recommendation
- "What does my recovery look like for tomorrow?"
- "Is my training load too high this week?"
- "Should I rest or train today based on last 7 days?"
