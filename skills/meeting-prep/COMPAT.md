# Compatibility notes for meeting-prep

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for ICS parsing, note retrieval, and optional chat delivery. |
| ZeroClaw | full | Grep-based note retrieval and local calendar parsing work well. |
| PicoClaw | partial | ICS parsing works, but direct `calcurse` integrations are often unavailable. |
| NullClaw | unsupported | Requires local files and optional outbound webhook delivery. |
| NanoBot | full | Strong fit for structured note retrieval and markdown brief assembly. |
| IronClaw | partial | Chat webhooks may be sandboxed; prefer local stdout review. |
