---
name: thumbnail-lab
description: Turn a short script into reusable thumbnail hooks, overlay copy, and shot prompts.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🎬"
    requires:
      bins: ['python3']
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
    tags: ['creative', 'thumbnail', 'video', 'copywriting']
---

# thumbnail-lab

## Purpose

Create a pragmatic thumbnail planning sheet from raw script text before design work starts.

## Runbook

1. Feed the helper a script file or pass text over stdin.
2. Run `scripts/spec.py` to generate headline options, short overlay phrases, and a simple shot list.
3. Use the output as a briefing aid for manual design instead of auto-publishing it unchanged.
4. Keep claims grounded in the source script to avoid misleading visual hooks.

## Stop conditions

1. Abort if the source script contains unsupported claims or regulated advice.
2. Abort before using a generated hook that materially overpromises the content.
3. Abort if the current variant is marked unsupported.

## Output format

- Headline options
- Short overlay copy ideas
- Shot prompts mapped to source beats

## Example invocations

- `python3 skills/thumbnail-lab/scripts/spec.py draft.txt`
- `cat outline.txt | python3 skills/thumbnail-lab/scripts/spec.py - --markdown`
