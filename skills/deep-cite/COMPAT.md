# Compatibility notes for deep-cite

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for source fetching, extraction, and markdown report generation. |
| ZeroClaw | full | Standard shell + Python pipeline works well with outbound HTTP. |
| PicoClaw | partial | HTML parsing works, but large source batches can be slow on constrained devices. |
| NullClaw | unsupported | Requires filesystem writes and outbound fetches. |
| NanoBot | full | Strong fit for Python-backed parsing and cleanup. |
| IronClaw | partial | Sandboxing may block remote fetches; use `MOCK_MODE=1` when offline. |
