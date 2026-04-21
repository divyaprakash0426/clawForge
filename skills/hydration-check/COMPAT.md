# Compatibility notes for hydration-check

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full local reporting works as documented. |
| ZeroClaw | full | Good fit for simple CSV processing. |
| PicoClaw | full | Lightweight enough for smaller devices when logs stay local. |
| NullClaw | partial | Read-only summary workflows can work, but storage and input options are limited. |
| NanoBot | full | Python data handling works well for this skill. |
| IronClaw | partial | Sandboxing is fine for local summaries but may limit file access outside approved paths. |
