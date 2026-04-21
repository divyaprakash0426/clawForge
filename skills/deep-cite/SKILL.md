---
name: deep-cite
description: Source-first research workflow with explicit claims and citations.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📚"
    requires:
      bins: ["curl", "jq", "python3"]
      env: ["OUTPUT_DIR", "SOURCE_DIR"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["research", "citations", "sources", "analysis"]
---

# deep-cite

## Purpose

Runs a transparent source-first research workflow: fetch URLs, extract candidate claims, and build citation-ready markdown outputs.

## Runbook

1. Prepare a `sources.txt` file listing one URL per line.
2. Set `SOURCE_DIR` and `OUTPUT_DIR` environment variables; create them if absent.
3. Run `scripts/fetch-sources.sh sources.txt` to download each source into `SOURCE_DIR/`.
4. Run `scripts/extract-claims.sh` to parse each downloaded file and emit `claims.json`.
5. Review `claims.json` and remove any false positives before proceeding.
6. Run `scripts/cite.sh claims.json` to produce:
   - `OUTPUT_DIR/citations.md` with a numbered bibliography
   - `OUTPUT_DIR/claims-annotated.md` with inline `[N]` reference markers
7. Print a summary: N sources processed, M claims extracted, P citations generated.

## Stop conditions

1. Abort if `SOURCE_DIR` or `OUTPUT_DIR` is unset.
2. Abort if every URL fetch fails; individual 4xx/5xx responses should be logged and skipped.
3. Never overwrite `OUTPUT_DIR` citation files without `FORCE=1`.
4. Abort if `claims.json` cannot be written.

## Output format

```json
{
  "sources_fetched": 5,
  "claims_extracted": 23,
  "citations_generated": 5,
  "output_dir": "/path/to/output"
}
```

## Example invocations

- `SOURCE_DIR=./sources OUTPUT_DIR=./output skills/deep-cite/scripts/run.sh sources.txt`
- `MOCK_MODE=1 skills/deep-cite/scripts/fetch-sources.sh sources.txt`
- "Run deep-cite on these 3 URLs and produce a citations.md file."
