---
name: changelog-weaver
description: Turn git history into release-note sections grouped by conventional commit intent.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📅"
    requires:
      bins: ['git', 'python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: ['productivity', 'git', 'release-notes', 'changelog']
---

# changelog-weaver

## Purpose

Build draft release notes from local git history without hand-sorting every commit.

## Runbook

1. Run the script inside a git repository and optionally provide a start and end ref.
2. Let `scripts/build.py` group commits by conventional prefixes such as feat, fix, docs, perf, and chore.
3. Review the generated markdown and edit wording for externally facing release notes.
4. Use the draft as a starting point, not as an automated public announcement.

## Stop conditions

1. Abort if the repository history is shallow or missing the comparison refs you need.
2. Abort before publishing notes without checking whether internal-only commits should be omitted.
3. Abort if the current variant is marked unsupported.

## Output format

- Markdown changelog grouped by release-note category
- Commit range metadata
- Catch-all section for uncategorized commits

## Example invocations

- `python3 skills/changelog-weaver/scripts/build.py`
- `python3 skills/changelog-weaver/scripts/build.py --from v1.2.0 --to HEAD`
