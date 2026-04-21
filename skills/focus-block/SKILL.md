---
name: focus-block
description: Pomodoro-aware focus session manager with DND and journal logging.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📅"
    requires:
      bins: ["bash", "calcurse", "jq"]
      env: ["CALDAV_URL", "CALDAV_USER", "CALDAV_PASS"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["productivity", "focus", "pomodoro", "calendar"]
---

# focus-block

## Purpose

Starts and ends Pomodoro-style focus sessions, toggles Do Not Disturb when available, and records the work in a markdown journal.

## Runbook

1. Set `JOURNAL_PATH` (default: `~/notes/focus-log.md`); create the file if absent.
2. Check whether a session is already open by looking for `status: open` in the journal.
3. Run `scripts/start-session.sh "task description"` to open a new session. The script generates a session ID, appends a journal record, and attempts to enable DND.
4. Work for 25 minutes; the start script prints the standard Pomodoro reminder.
5. Run `scripts/end-session.sh` to close the active session and record its duration.
6. After every 4 completed Pomodoros, suggest a 20-minute break.
7. Run `scripts/status.sh` at any time to review today’s focus history.

## Stop conditions

1. Warn but do not abort if DND integration is unavailable.
2. Abort if `JOURNAL_PATH` resolves to a directory.
3. Do not allow two open sessions simultaneously; abort with an informative message.
4. Never delete journal entries.

## Output format

A completed journal entry appended to `JOURNAL_PATH`:

```
## Focus Session 20240615-a3f1
- task: Write architecture doc
- start: 2024-06-15T14:30:00
- end: 2024-06-15T14:55:00
- duration_minutes: 25
- status: complete
```

## Example invocations

- `JOURNAL_PATH=~/notes/focus-log.md skills/focus-block/scripts/start-session.sh "write SKILL.md docs"`
- `skills/focus-block/scripts/end-session.sh`
- `skills/focus-block/scripts/status.sh`
- "Start a 25-minute focus block for writing the weekly brief."
