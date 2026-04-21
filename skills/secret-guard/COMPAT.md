# Compatibility notes for secret-guard

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for local repository scans where masking and remediation can happen immediately in the same shell session. |
| ZeroClaw | full | Works well in CI or pre-merge review pipelines that need a deterministic JSON artifact. |
| PicoClaw | partial | The built-in regex fallback works, but large repo scans with external tools may be slower on constrained ARM boards. |
| NullClaw | unsupported | NullClaw targets typically lack the repository tooling and filesystem access needed for meaningful secret scans. |
| NanoBot | full | Good for summarizing findings and remediation steps while keeping the raw scan local and masked. |
| IronClaw | full | Sandboxed execution is still useful because the skill only reads files and emits masked findings. |
