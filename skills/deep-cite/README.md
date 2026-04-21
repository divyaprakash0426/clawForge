# deep-cite

## What it does

Downloads a list of web sources, extracts candidate evidence sentences from the
saved HTML, and generates citation-ready markdown outputs that keep claims tied to
their originating source files.

## Prerequisites

- `curl`, `jq`, and `python3` in PATH
- `SOURCE_DIR` for raw HTML snapshots
- `OUTPUT_DIR` for generated citation artifacts
- A `sources.txt` file with one URL per line

## Directory contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | Workflow and review guardrails |
| `COMPAT.md` | Variant-specific notes |
| `install.sh` | Dependency and directory validation |
| `scripts/fetch-sources.sh` | Download each source and build a source map |
| `scripts/extract-claims.sh` | Strip HTML and collect claim-like sentences |
| `scripts/cite.sh` | Generate `citations.md` and `claims-annotated.md` |
| `scripts/run.sh` | End-to-end wrapper around the three phases |

## Quick start

```bash
export SOURCE_DIR=./sources
export OUTPUT_DIR=./output
skills/deep-cite/scripts/run.sh sources.txt
```

## Mock mode

```bash
MOCK_MODE=1 SOURCE_DIR=./sources OUTPUT_DIR=./output skills/deep-cite/scripts/run.sh sources.txt
```
