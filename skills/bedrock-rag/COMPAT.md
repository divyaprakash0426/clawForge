# Compatibility notes for bedrock-rag

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for AWS-authenticated indexing and validation queries. |
| ZeroClaw | full | Works well when AWS CLI access and outbound HTTPS are allowed. |
| PicoClaw | partial | Semantic sync works, but constrained CPUs benefit from smaller corpora. |
| NullClaw | unsupported | No AWS API access or persistent local corpus handling. |
| NanoBot | full | Strong fit for markdown preprocessing and Bedrock scripting. |
| IronClaw | partial | Sandboxing often blocks AWS credentials or Bedrock endpoints; use `MOCK_MODE=1` for offline validation. |
