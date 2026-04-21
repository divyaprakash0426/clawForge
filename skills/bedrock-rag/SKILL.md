---
name: bedrock-rag
description: Indexes local markdown into a Bedrock-backed retrieval workflow.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📚"
    requires:
      bins: ["python3", "aws", "jq"]
      env: ["AWS_PROFILE", "AWS_REGION", "BEDROCK_KB_ID", "BEDROCK_MODEL_ID"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["research", "bedrock", "rag", "knowledge-base"]
---

# bedrock-rag

## Purpose

Chunks local markdown corpora and syncs them into an Amazon Bedrock Knowledge Base for semantic retrieval.

## Runbook

1. Verify `aws`, `python3`, and `jq` are in PATH, then validate credentials with `aws sts get-caller-identity --no-cli-pager`.
2. Confirm `BEDROCK_KB_ID` and `BEDROCK_MODEL_ID` are set, and ensure `AWS_REGION` matches the Bedrock region hosting the knowledge base.
3. Run `scripts/chunk.sh SOURCE_DIR` to split all `.md` files into roughly 500-word JSONL chunks containing `chunk_id`, `source_file`, and `content`.
4. Review the chunk count before indexing; abort if the chunk count exceeds `1000` unless `FORCE=1` is explicitly set.
5. Run `scripts/index.sh CHUNKS_PATH` to sync the chunk stream into the Bedrock Knowledge Base. The script ingests documents and then triggers a Bedrock ingestion job for auditable sync status.
6. Poll `aws bedrock-agent get-ingestion-job` until the job reports `COMPLETE`; abort on `FAILED` or `STOPPED`.
7. Run `scripts/query.sh "your question"` to verify semantic retrieval and inspect the returned citations.

## Stop conditions

1. Abort if `aws sts get-caller-identity` fails.
2. Abort if chunk count exceeds `1000` unless `FORCE=1`.
3. Never delete existing knowledge-base contents — only add or update documents.
4. Abort if the Bedrock ingestion job returns `FAILED` or `STOPPED`.

## Output format

```json
{
  "chunks_synced": 128,
  "kb_id": "KB12345678",
  "model_id": "anthropic.claude-3-sonnet-20240229-v1:0",
  "sync_status": "COMPLETE"
}
```

## Example invocations

- `skills/bedrock-rag/scripts/chunk.sh docs > docs/.bedrock-rag.chunks.jsonl`
- `skills/bedrock-rag/scripts/index.sh docs/.bedrock-rag.chunks.jsonl`
- `skills/bedrock-rag/scripts/query.sh "What deployment steps are documented?"`
- `skills/bedrock-rag/scripts/run.sh docs --query "What changed in the onboarding guide?"`
