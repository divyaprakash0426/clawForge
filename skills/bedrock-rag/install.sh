#!/usr/bin/env bash
set -euo pipefail

fail=0
for bin in aws python3 jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "bedrock-rag: missing required binary: $bin" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || exit 1

: "${AWS_REGION:?bedrock-rag: set AWS_REGION}"
: "${BEDROCK_KB_ID:?bedrock-rag: set BEDROCK_KB_ID}"
: "${BEDROCK_MODEL_ID:?bedrock-rag: set BEDROCK_MODEL_ID}"

if ! printf '%s' "$AWS_REGION" | grep -Eq '^[a-z]{2}-[a-z]+-[0-9]+$'; then
  echo "bedrock-rag: AWS_REGION does not look valid: $AWS_REGION" >&2
  exit 1
fi

if [ "${MOCK_MODE:-0}" != "1" ]; then
  aws sts get-caller-identity --no-cli-pager >/dev/null
fi

echo "bedrock-rag: dependencies and AWS configuration look ready."
