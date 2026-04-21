#!/usr/bin/env bash
set -euo pipefail

query="${*:-}"
if [ -z "$query" ]; then
  echo "bedrock-rag query: usage: query.sh \"your question\"" >&2
  exit 1
fi

if [ "${MOCK_MODE:-0}" = "1" ]; then
  cat <<EOF
Answer: The sample corpus describes agentic workflows and Model Context Protocol coordination for tool-using assistants.

Sources:
1. mock/agentic-ai.md
2. mock/model-context-protocol.md
EOF
  exit 0
fi

: "${AWS_REGION:?bedrock-rag query: set AWS_REGION}"
: "${BEDROCK_KB_ID:?bedrock-rag query: set BEDROCK_KB_ID}"
: "${BEDROCK_MODEL_ID:?bedrock-rag query: set BEDROCK_MODEL_ID}"

model_ref="$BEDROCK_MODEL_ID"
if [[ "$model_ref" != arn:* ]]; then
  model_ref="arn:aws:bedrock:${AWS_REGION}::foundation-model/${model_ref}"
fi

input_payload="$(QUERY_TEXT="$query" python3 - <<'PY'
import json
import os
print(json.dumps({"text": os.environ["QUERY_TEXT"]}))
PY
)"

config_payload="$(MODEL_REF="$model_ref" python3 - <<'PY'
import json
import os
print(json.dumps({
    "type": "KNOWLEDGE_BASE",
    "knowledgeBaseConfiguration": {
        "knowledgeBaseId": os.environ["BEDROCK_KB_ID"],
        "modelArn": os.environ["MODEL_REF"],
        "retrievalConfiguration": {
            "vectorSearchConfiguration": {
                "numberOfResults": int(os.environ.get("BEDROCK_RESULT_COUNT", "5"))
            }
        }
    }
}))
PY
)"

response="$(aws bedrock-agent-runtime retrieve-and-generate \
  --region "$AWS_REGION" \
  --no-cli-pager \
  --input "$input_payload" \
  --retrieve-and-generate-configuration "$config_payload")"

RESPONSE_JSON="$response" python3 - <<'PY'
import json
import os

response = json.loads(os.environ["RESPONSE_JSON"])
output = response.get("output", {})
answer = output.get("text") if isinstance(output, dict) else str(output)
answer = answer or "No answer returned."
print(f"Answer: {answer}\n")
print("Sources:")

citations = response.get("citations") or []
seen = set()
counter = 0
for citation in citations:
    references = citation.get("retrievedReferences") or citation.get("references") or []
    for ref in references:
        location = ref.get("location", {})
        source = (
            location.get("s3Location", {}).get("uri")
            or location.get("webLocation", {}).get("url")
            or location.get("customDocumentLocation", {}).get("id")
            or ref.get("metadata", {}).get("source_file")
            or ref.get("content", {}).get("text", "")[:120]
            or "Unknown source"
        )
        if source in seen:
            continue
        seen.add(source)
        counter += 1
        print(f"{counter}. {source}")
if counter == 0:
    print("1. No citations were returned by Bedrock.")
PY
