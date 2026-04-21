#!/usr/bin/env bash
set -euo pipefail

CHUNKS_PATH="${1:-}"
if [ -z "$CHUNKS_PATH" ]; then
  echo "bedrock-rag index: usage: index.sh CHUNKS_PATH" >&2
  exit 1
fi
if [ ! -f "$CHUNKS_PATH" ]; then
  echo "bedrock-rag index: chunks file not found: $CHUNKS_PATH" >&2
  exit 1
fi

chunk_count="$(python3 - "$CHUNKS_PATH" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
print(sum(1 for line in path.read_text(encoding='utf-8').splitlines() if line.strip()))
PY
)"

if [ "$chunk_count" -gt 1000 ] && [ "${FORCE:-0}" != "1" ]; then
  echo "bedrock-rag index: refusing to sync $chunk_count chunks without FORCE=1." >&2
  exit 1
fi

if [ "${MOCK_MODE:-0}" = "1" ]; then
  CHUNK_COUNT="$chunk_count" python3 - <<'PY'
import json
import os
print(json.dumps({
    "chunks_synced": int(os.environ["CHUNK_COUNT"]),
    "kb_id": os.environ.get("BEDROCK_KB_ID", "mock-kb"),
    "model_id": os.environ.get("BEDROCK_MODEL_ID", "mock-model"),
    "sync_status": "MOCK_COMPLETE",
}, indent=2))
PY
  exit 0
fi

: "${AWS_REGION:?bedrock-rag index: set AWS_REGION}"
: "${BEDROCK_KB_ID:?bedrock-rag index: set BEDROCK_KB_ID}"
: "${BEDROCK_MODEL_ID:?bedrock-rag index: set BEDROCK_MODEL_ID}"

data_source_id="${BEDROCK_DATA_SOURCE_ID:-}"
if [ -z "$data_source_id" ]; then
  data_source_id="$(aws bedrock-agent list-data-sources --region "$AWS_REGION" --no-cli-pager --knowledge-base-id "$BEDROCK_KB_ID" | jq -r '.dataSourceSummaries[0].dataSourceId // .dataSources[0].dataSourceId // empty')"
fi
if [ -z "$data_source_id" ]; then
  echo "bedrock-rag index: could not determine a Bedrock data source ID. Set BEDROCK_DATA_SOURCE_ID." >&2
  exit 1
fi

while IFS= read -r batch_json; do
  [ -n "$batch_json" ] || continue
  response="$(aws bedrock-agent ingest-knowledge-base-documents \
    --region "$AWS_REGION" \
    --no-cli-pager \
    --knowledge-base-id "$BEDROCK_KB_ID" \
    --data-source-id "$data_source_id" \
    --documents "$batch_json")"

  if ! BATCH_RESPONSE="$response" python3 - <<'PY'
import json
import os
import sys

response = json.loads(os.environ["BATCH_RESPONSE"])
bad = []
for item in response.get("documentDetails", []):
    status = item.get("status", "")
    if status in {"FAILED", "PARTIALLY_INDEXED", "METADATA_PARTIALLY_INDEXED"}:
        bad.append({
            "identifier": item.get("identifier", {}),
            "status": status,
            "statusReason": item.get("statusReason", ""),
        })
if bad:
    print(json.dumps(bad, indent=2))
    sys.exit(1)
PY
  then
    echo "bedrock-rag index: document ingestion returned a non-success status." >&2
    exit 1
  fi
done < <(CHUNKS_PATH="$CHUNKS_PATH" BATCH_SIZE="${BATCH_SIZE:-10}" python3 - <<'PY'
import json
import os
import pathlib

path = pathlib.Path(os.environ["CHUNKS_PATH"])
batch_size = int(os.environ.get("BATCH_SIZE", "10"))
rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]

for start in range(0, len(rows), batch_size):
    batch = rows[start:start + batch_size]
    documents = []
    for row in batch:
        documents.append({
            "metadata": {
                "type": "IN_LINE_ATTRIBUTE",
                "inlineAttributes": [
                    {"key": "chunk_id", "value": {"type": "STRING", "stringValue": row["chunk_id"]}},
                    {"key": "source_file", "value": {"type": "STRING", "stringValue": row["source_file"]}},
                ],
            },
            "content": {
                "dataSourceType": "CUSTOM",
                "custom": {
                    "customDocumentIdentifier": {"id": row["chunk_id"]},
                    "sourceType": "IN_LINE",
                    "inlineContent": {
                        "type": "TEXT",
                        "textContent": {"data": row["content"]},
                    },
                },
            },
        })
    print(json.dumps(documents, separators=(",", ":")))
PY
)

job_start="$(aws bedrock-agent start-ingestion-job \
  --region "$AWS_REGION" \
  --no-cli-pager \
  --knowledge-base-id "$BEDROCK_KB_ID" \
  --data-source-id "$data_source_id" \
  --description "bedrock-rag sync $(date -u +%FT%TZ)")"

ingestion_job_id="$(printf '%s' "$job_start" | jq -r '.ingestionJob.ingestionJobId // .ingestionJobId // empty')"
sync_status="$(printf '%s' "$job_start" | jq -r '.ingestionJob.status // .status // empty')"

if [ -z "$ingestion_job_id" ]; then
  echo "bedrock-rag index: failed to obtain ingestion job ID." >&2
  exit 1
fi

while :; do
  case "$sync_status" in
    COMPLETE)
      break
      ;;
    FAILED|STOPPED)
      echo "bedrock-rag index: ingestion job ended with status $sync_status." >&2
      exit 1
      ;;
    STARTING|IN_PROGRESS|STOPPING|"")
      sleep "${POLL_INTERVAL:-10}"
      job_state="$(aws bedrock-agent get-ingestion-job \
        --region "$AWS_REGION" \
        --no-cli-pager \
        --knowledge-base-id "$BEDROCK_KB_ID" \
        --data-source-id "$data_source_id" \
        --ingestion-job-id "$ingestion_job_id")"
      sync_status="$(printf '%s' "$job_state" | jq -r '.ingestionJob.status // .status // empty')"
      ;;
    *)
      echo "bedrock-rag index: unrecognized ingestion status: $sync_status" >&2
      exit 1
      ;;
  esac
done

CHUNK_COUNT="$chunk_count" SYNC_STATUS="$sync_status" python3 - <<'PY'
import json
import os
print(json.dumps({
    "chunks_synced": int(os.environ["CHUNK_COUNT"]),
    "kb_id": os.environ["BEDROCK_KB_ID"],
    "model_id": os.environ["BEDROCK_MODEL_ID"],
    "sync_status": os.environ["SYNC_STATUS"],
}, indent=2))
PY
