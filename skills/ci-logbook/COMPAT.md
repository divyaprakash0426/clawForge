# Compatibility notes for ci-logbook

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full local log triage and markdown reporting work as documented. |
| ZeroClaw | full | Efficient for text-heavy workflows where logs are already local. |
| PicoClaw | partial | Useful for smaller logs, but memory limits can constrain large artifact review. |
| NullClaw | partial | Read-only text review can work, but large-file handling is limited. |
| NanoBot | full | Python-native environments are a strong fit for regex-driven summarization. |
| IronClaw | partial | Sandboxing may block direct access to downloaded workflow artifacts. |
