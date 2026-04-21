# bedrock-rag

## What it does

Converts local markdown documentation into ~500-word JSONL chunks, ingests those
chunks into an Amazon Bedrock Knowledge Base, and provides a query helper that
exercises `retrieve-and-generate` with source citations.

## Prerequisites

- AWS account with Amazon Bedrock Knowledge Base enabled
- IAM permissions for `bedrock-agent`, `bedrock-agent-runtime`, and `sts:GetCallerIdentity`
- `aws`, `python3`, and `jq` in PATH
- `AWS_REGION`, `BEDROCK_KB_ID`, and `BEDROCK_MODEL_ID` exported
- Optional but recommended: `BEDROCK_DATA_SOURCE_ID` if your knowledge base has more than one data source

## Directory contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | Runbook and operator guardrails |
| `COMPAT.md` | Claw variant compatibility notes |
| `install.sh` | Dependency and credential validation |
| `scripts/chunk.sh` | Split markdown into JSONL chunks |
| `scripts/index.sh` | Ingest chunks and poll Bedrock sync status |
| `scripts/query.sh` | Ask the knowledge base a question |
| `scripts/run.sh` | End-to-end helper for chunk + index (+ optional query) |

## Quick start

```bash
export AWS_REGION=us-east-1
export BEDROCK_KB_ID=KB12345678
export BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

skills/bedrock-rag/scripts/run.sh docs --query "What onboarding steps are documented?"
```

## Mock mode

```bash
MOCK_MODE=1 skills/bedrock-rag/scripts/chunk.sh docs
MOCK_MODE=1 skills/bedrock-rag/scripts/index.sh docs/.bedrock-rag.chunks.jsonl
MOCK_MODE=1 skills/bedrock-rag/scripts/query.sh "Summarize the sample corpus"
```
