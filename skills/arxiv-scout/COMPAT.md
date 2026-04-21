# Compatibility notes for arxiv-scout

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full arXiv polling + Telegram push. Run on cron or as a scheduled skill. |
| ZeroClaw | full | Shell pipeline works natively; Telegram curl call requires outbound HTTP. |
| PicoClaw | partial | Can fetch and append notes, but cron scheduling must be set up manually. |
| NullClaw | unsupported | No outbound HTTP or filesystem append in ultra-embedded targets. |
| NanoBot | full | Ideal Python-adjacent environment; `MOCK_MODE=1` useful for offline tests. |
| IronClaw | partial | Sandboxed HTTP may block arXiv calls; use `MOCK_MODE=1` inside the sandbox. |
