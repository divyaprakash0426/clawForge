---
name: weekly-brief
description: Compiles a weekly digest from git history, PRs, calendars, and logbooks.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📅"
    requires:
      bins: ["git", "gh", "jq", "date"]
      env: ["GITHUB_TOKEN", "CALENDAR_TOKEN", "LOGBOOK_PATH"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["productivity", "digest", "git", "calendar"]
---

# weekly-brief

## Purpose

Compiles a weekly digest from git history, merged pull requests, a markdown logbook, and optional notification delivery.

## Runbook

1. Set `REPO_LIST` (space-separated absolute paths to git repos), `LOGBOOK_PATH`, and `GITHUB_TOKEN`.
2. Run `scripts/git-digest.sh` to collect commits from the past 7 days across all listed repositories.
3. Run `scripts/pr-digest.sh` to collect merged PRs via the GitHub CLI.
4. Run `scripts/logbook-digest.sh` to extract diary or logbook entries from the past 7 days.
5. Pipe or pass all three outputs to `scripts/assemble.sh` to produce a unified markdown brief.
6. Print the brief to stdout; optionally send it to Telegram if bot credentials are set.

## Stop conditions

1. Warn and skip any repo path that does not exist.
2. Abort if `git` is missing.
3. Skip the PR digest gracefully if `GITHUB_TOKEN` is unset.
4. Skip the logbook digest if `LOGBOOK_PATH` is unset or missing.

## Output format

A markdown document with these sections:

- `## Git Activity`
- `## Merged PRs`
- `## Logbook`
- `## Summary`

## Example invocations

- `REPO_LIST="~/code/myapp ~/code/api" LOGBOOK_PATH=~/notes/log.md skills/weekly-brief/scripts/run.sh`
- "Compile my weekly brief for the past 7 days."
