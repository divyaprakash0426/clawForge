# Compatibility notes for dep-hygiene

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Full repository scans and report generation work as documented. |
| ZeroClaw | full | Good fit for low-overhead filesystem audits. |
| PicoClaw | partial | Best when scoped to a smaller workspace subtree. |
| NullClaw | partial | Read-only dependency review can work, but broader repository traversal is limited. |
| NanoBot | full | Python runtime makes manifest parsing straightforward. |
| IronClaw | full | Static manifest inspection fits well inside sandboxed environments. |
