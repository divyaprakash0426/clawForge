---
name: meeting-prep
description: Pre-meeting agenda and notes briefing generator.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📅"
    requires:
      bins: ["calcurse", "curl", "jq"]
      env: ["CALENDAR_TOKEN", "MEMORY_PATH", "CHAT_WEBHOOK"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["productivity", "meetings", "briefing", "notes"]
---

# meeting-prep

## Purpose

Prepares a just-in-time meeting brief by combining the next calendar event with relevant notes from `MEMORY.md`.

## Runbook

1. Ensure `MEMORY_PATH` and `CALENDAR_ICS` (or calcurse access) are set.
2. Run `scripts/next-event.sh` to find the next meeting within the next 24 hours.
3. If no event is found, print `No upcoming events in the next 24 hours.` and exit cleanly.
4. Extract keywords from the event title and strip common words such as `meeting`, `call`, `sync`, and `standup`.
5. Run `scripts/retrieve-notes.sh <keywords>` to find relevant `MEMORY.md` sections.
6. Run `scripts/brief.sh` to assemble and print the final meeting brief.
7. Optionally post the brief to `CHAT_WEBHOOK` via `curl`, but only when `SEND_TO_CHAT=1` is explicitly set.

## Stop conditions

1. Exit cleanly if no upcoming event is found.
2. Abort if `MEMORY_PATH` is unset or points to a directory.
3. Never post to `CHAT_WEBHOOK` without `SEND_TO_CHAT=1`.
4. Abort if `brief.sh` cannot write to stdout.

## Output format

```markdown
# Meeting Brief: Sprint Planning
**Time**: 2024-06-15 10:00  
**Attendees**: alice@example.com, bob@example.com  

## Agenda
(from calendar description or "No agenda provided")

## Related Notes from Memory
> From MEMORY.md § "Sprint Planning Notes"  
> Last sprint velocity was 34 points...

## Talking Points
- TBD — review backlog before meeting
- TBD — confirm acceptance criteria for Story #42
```

## Example invocations

- `MEMORY_PATH=~/notes/MEMORY.md CALENDAR_ICS=~/cal.ics skills/meeting-prep/scripts/run.sh`
- `MOCK_MODE=1 MEMORY_PATH=~/notes/MEMORY.md skills/meeting-prep/scripts/run.sh`
- "What's my next meeting and what should I know before joining?"
