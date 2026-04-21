# arxiv-scout

## What it does

Polls the arXiv Atom API for new agentic-AI and MCP papers, deduplicates against
your local knowledge-base file, and appends formatted markdown notes.

## Prerequisites

- `curl` and `jq` in PATH
- `MEMORY_PATH` env var pointing to a writable markdown file
- Optional: `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` for push notifications

## Directory contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | Machine-readable skill metadata and runbook |
| `COMPAT.md` | Per-variant compatibility notes |
| `install.sh` | Dependency check and first-run validation |
| `scripts/fetch.sh` | Query arXiv Atom API, emit JSON. Supports `MOCK_MODE=1`. |
| `scripts/sync-notes.sh` | Deduplicate and append new notes to `MEMORY_PATH`. |
| `scripts/run.sh` | End-to-end convenience wrapper. |

## Quick start

```bash
export MEMORY_PATH=~/notes/MEMORY.md
skills/arxiv-scout/scripts/run.sh
```

## Mock mode (no network)

```bash
MOCK_MODE=1 MEMORY_PATH=./test-memory.md skills/arxiv-scout/scripts/run.sh
```
