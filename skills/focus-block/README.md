# focus-block

## What it does

Opens and closes Pomodoro-style focus sessions, writes durable markdown journal
entries, and attempts to toggle Do Not Disturb when the host desktop supports it.

## Quick start

```bash
skills/focus-block/scripts/start-session.sh "write the weekly brief"
skills/focus-block/scripts/end-session.sh
skills/focus-block/scripts/status.sh
```

## Journal format

Each session is stored as a markdown block in `JOURNAL_PATH` (default: `~/notes/focus-log.md`).
Open sessions are recorded with `status: open` and completed sessions are rewritten in-place with
an end timestamp and duration.

## DND support

| Platform | Behavior |
| --- | --- |
| GNOME (`gsettings`) | Attempts to disable banners on start and restore them on end |
| macOS | No-op by default; script logs a warning |
| Other / headless | No-op with a warning; journal logging still works |
