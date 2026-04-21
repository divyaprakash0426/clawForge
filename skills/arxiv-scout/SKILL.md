---
name: arxiv-scout
description: Monitors arXiv for agentic AI and MCP papers and syncs structured notes.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📚"
    requires:
      bins: ["curl", "jq", "python3"]
      env: ["TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID", "MEMORY_PATH"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["research", "arxiv", "knowledge", "mcp"]
---

# arxiv-scout

## Purpose

Monitors arXiv for newly submitted papers tagged with agentic AI or MCP keywords.
Appends deduplicated markdown notes to a local knowledge-base file.

## Runbook

1. Verify that `curl`, `jq`, and `python3` are available; abort if any are missing.
2. Confirm `MEMORY_PATH` points to a writable file (create it empty if absent).
3. Run `scripts/fetch.sh` to query the arXiv Atom API for papers matching:
   `ti:agentic OR ti:MCP OR abs:model-context-protocol OR abs:agentic-AI`
   with `max_results=20` ordered by `submittedDate` descending.
4. Inspect the returned JSON: each entry should have `id`, `title`, `authors`, `published`, `summary`, and `link`.
5. Run `scripts/sync-notes.sh` to deduplicate against existing entries in `MEMORY_PATH` by arxiv ID, then append new formatted notes.
6. Print a summary: N new papers appended, M duplicates skipped.
7. Optionally, if `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are set, send the summary line to Telegram via `curl`.

## Stop conditions

1. Abort if `curl` or `jq` is missing from PATH.
2. Abort if `MEMORY_PATH` is unset or resolves to a directory.
3. Abort if the arXiv API returns HTTP status other than 200 (unless `MOCK_MODE=1`).
4. Never overwrite `MEMORY_PATH` — only append; abort if the file is not writable.

## Output format

```json
{
  "fetched": 20,
  "new": 5,
  "skipped": 15,
  "appended_ids": ["2406.12345", "2406.12346"],
  "memory_path": "/path/to/MEMORY.md"
}
```

A markdown note block per new paper is appended to `MEMORY_PATH`:

```
## [2406.12345] Agentic AI for Code Review
**Authors**: Alice Smith, Bob Jones  
**Published**: 2024-06-15  
**Summary**: We present a multi-agent framework for automated code review...  
**Link**: https://arxiv.org/abs/2406.12345
```

## Example invocations

- `MEMORY_PATH=~/notes/MEMORY.md skills/arxiv-scout/scripts/run.sh`
- `MOCK_MODE=1 skills/arxiv-scout/scripts/fetch.sh`
- "Run arxiv-scout and tell me what new MCP papers were published this week."
- "Check arXiv for agentic AI papers and append summaries to my knowledge base."
