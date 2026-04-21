# Compatibility notes for weekly-brief

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Strong fit for multi-repo summaries and GitHub-backed reporting. |
| ZeroClaw | full | Works well with local git repos and outbound API access. |
| PicoClaw | partial | Git summaries work, but `gh` access may be limited or too heavy. |
| NullClaw | unsupported | Requires git history, filesystem access, and optional GitHub APIs. |
| NanoBot | full | Good environment for JSON assembly and markdown reporting. |
| IronClaw | partial | Sandboxing can restrict repo traversal or GitHub API calls. |
