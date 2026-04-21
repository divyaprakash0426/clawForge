# Compatibility notes for kube-scout

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for full manifest review before apply. |
| ZeroClaw | full | Runs well for static YAML review on low-resource hosts. |
| PicoClaw | partial | Useful for small manifest sets, though larger repos may need scoped runs. |
| NullClaw | unsupported | Unsupported because the documented workflow depends on Python YAML parsing and local file inspection. |
| NanoBot | full | Strong fit for Python-native policy checks and report generation. |
| IronClaw | partial | Sandboxed environments may limit manifest access outside approved workspaces. |
