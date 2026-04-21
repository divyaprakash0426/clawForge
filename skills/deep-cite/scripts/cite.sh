#!/usr/bin/env bash
set -euo pipefail

CLAIMS_JSON="${1:-}"
: "${OUTPUT_DIR:?deep-cite cite: set OUTPUT_DIR}"
: "${SOURCE_DIR:?deep-cite cite: set SOURCE_DIR}"

if [ -z "$CLAIMS_JSON" ] || [ ! -f "$CLAIMS_JSON" ]; then
  echo "deep-cite cite: usage: cite.sh claims.json" >&2
  exit 1
fi

citations_path="$OUTPUT_DIR/citations.md"
annotated_path="$OUTPUT_DIR/claims-annotated.md"
if [ "${FORCE:-0}" != "1" ] && { [ -e "$citations_path" ] || [ -e "$annotated_path" ]; }; then
  echo "deep-cite cite: output files already exist. Re-run with FORCE=1 to overwrite." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

CLAIMS_JSON="$CLAIMS_JSON" OUTPUT_DIR="$OUTPUT_DIR" SOURCE_DIR="$SOURCE_DIR" python3 - <<'PY'
import json
import os
import pathlib

claims = json.loads(pathlib.Path(os.environ["CLAIMS_JSON"]).read_text(encoding="utf-8"))
source_map_path = pathlib.Path(os.environ["SOURCE_DIR"]) / "source-map.json"
source_map = json.loads(source_map_path.read_text(encoding="utf-8")) if source_map_path.exists() else []
lookup = {item["source_file"]: item.get("url", "Unknown URL") for item in source_map}

citations_path = pathlib.Path(os.environ["OUTPUT_DIR"]) / "citations.md"
annotated_path = pathlib.Path(os.environ["OUTPUT_DIR"]) / "claims-annotated.md"

ordered_sources = []
for claim in claims:
    source = claim.get("source_file")
    if source and source not in ordered_sources:
        ordered_sources.append(source)

citation_numbers = {source: index for index, source in enumerate(ordered_sources, start=1)}

bibliography_lines = ["# Bibliography", ""]
for source in ordered_sources:
    bibliography_lines.append(f"{citation_numbers[source]}. `{source}` — {lookup.get(source, 'Unknown URL')}")
if len(bibliography_lines) == 2:
    bibliography_lines.append("No sources were cited.")

annotated_lines = ["# Claims with Inline Citations", ""]
for claim in claims:
    source = claim.get("source_file", "unknown-source")
    number = citation_numbers.get(source, "?")
    annotated_lines.append(
        f"- {claim.get('claim_text', '').strip()} [{number}] _(source: {source}, line {claim.get('line_number', '?')})_"
    )
if len(annotated_lines) == 2:
    annotated_lines.append("No claims were extracted.")

citations_path.write_text("\n".join(bibliography_lines) + "\n", encoding="utf-8")
annotated_path.write_text("\n".join(annotated_lines) + "\n", encoding="utf-8")

print(
    json.dumps(
        {
            "sources_fetched": len(ordered_sources),
            "claims_extracted": len(claims),
            "citations_generated": len(ordered_sources),
            "output_dir": os.environ["OUTPUT_DIR"],
        },
        indent=2,
    )
)
PY
