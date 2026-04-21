# Compatibility notes for permission-lens

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Native Python support makes local frontmatter parsing and pre-install permission review straightforward. |
| ZeroClaw | full | Good fit for CI or remote review environments where only `SKILL.md` inspection is needed. |
| PicoClaw | partial | Parsing works, but ANSI color and bulk skill inspection are less comfortable on tiny terminals and lower-power boards. |
| NullClaw | partial | Static metadata review is safe, but some NullClaw images may omit Python or filesystem conveniences. |
| NanoBot | full | Excellent for presenting manifests in chat or approval workflows before installation proceeds. |
| IronClaw | full | Sandboxing is fine because the tool only reads metadata and emits local text or JSON. |
