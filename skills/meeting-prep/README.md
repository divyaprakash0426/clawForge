# meeting-prep

## What it does

Looks up the next calendar event, retrieves matching note excerpts from `MEMORY.md`,
and assembles a compact meeting brief you can review before joining.

## Prerequisites

- `MEMORY_PATH` pointing to a markdown memory file
- One calendar source:
  - `CALENDAR_ICS=/path/to/calendar.ics`
  - or local `calcurse` access
  - or `MOCK_MODE=1` for offline tests
- Optional `CHAT_WEBHOOK` if you want to post the brief to Slack or Teams

## Quick start

```bash
export MEMORY_PATH=~/notes/MEMORY.md
export CALENDAR_ICS=~/calendar.ics
skills/meeting-prep/scripts/run.sh
```

## Calendar source notes

- ICS parsing is the most complete path and includes attendees + descriptions.
- `calcurse` fallback is best-effort and focuses on the next appointment summary.
- `MOCK_MODE=1` returns a sample event for safe local testing.

## Chat webhook delivery

Set `SEND_TO_CHAT=1` alongside `CHAT_WEBHOOK` to post the generated brief. Without the
explicit flag, the script prints locally only.
