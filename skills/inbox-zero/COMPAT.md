# Compatibility notes for inbox-zero

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Good fit for header-only IMAP triage with human approval loops. |
| ZeroClaw | full | Shell and Python helpers work well when outbound IMAP is allowed. |
| PicoClaw | partial | Triage logic runs fine, but mailbox fetch latency may be noticeable. |
| NullClaw | unsupported | No outbound IMAP or secure credential handling. |
| NanoBot | full | Strong environment for parsing headers and summarizing priorities. |
| IronClaw | partial | Default to `MOCK_MODE=1`; sandboxed runtimes often block IMAP. |
