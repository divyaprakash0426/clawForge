# Compatibility notes for repo-radar

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full repository scans work as documented. |
| ZeroClaw | full | Static inventory tasks fit well on lower-resource hosts. |
| PicoClaw | partial | Best when scoped to a smaller subtree. |
| NullClaw | partial | Read-only summaries can work, but broad repository walks are limited. |
| NanoBot | full | Python tooling makes repo inventory straightforward. |
| IronClaw | full | Static file inventory is a good fit for sandboxed environments. |
