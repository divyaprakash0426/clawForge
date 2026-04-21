# weekly-brief

## What it does

Collects the last seven days of git commits, merged pull requests, and logbook notes,
then assembles them into a weekly markdown brief suitable for status updates or team check-ins.

## Prerequisites

- `git`, `gh`, `jq`, and `python3` in PATH
- `REPO_LIST` containing absolute repository paths separated by spaces
- Optional `GITHUB_TOKEN` for merged PR lookup
- Optional `LOGBOOK_PATH` for personal notes
- Optional `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` for push delivery

## Directory contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | Runbook and operator-facing expectations |
| `COMPAT.md` | Variant-specific constraints |
| `install.sh` | Dependency checks |
| `scripts/git-digest.sh` | Collect commits from the last 7 days |
| `scripts/pr-digest.sh` | Collect merged PR metadata via `gh` |
| `scripts/logbook-digest.sh` | Extract recent dated logbook sections |
| `scripts/assemble.sh` | Render the final markdown brief |
| `scripts/run.sh` | End-to-end wrapper |

## Quick start

```bash
export REPO_LIST="/abs/path/to/app /abs/path/to/api"
export LOGBOOK_PATH=~/notes/logbook.md
skills/weekly-brief/scripts/run.sh
```
