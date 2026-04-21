# Compatibility notes for changelog-weaver

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full git-backed release note drafting is supported. |
| ZeroClaw | full | Works well when git history is local and complete. |
| PicoClaw | partial | Useful for smaller repositories or narrowed ranges. |
| NullClaw | unsupported | Unsupported because the documented workflow depends on local git history access. |
| NanoBot | full | Python and git combine well for changelog generation. |
| IronClaw | partial | Sandboxing may prevent access to the full repository history. |
