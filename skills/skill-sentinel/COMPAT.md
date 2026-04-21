# Compatibility notes for skill-sentinel

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for local filesystem scans and remote URL reviews before a skill is copied into the runtime. |
| ZeroClaw | full | Works well in CI or remote shells where Python is available and install gating needs a deterministic exit code. |
| PicoClaw | partial | The scanner works, but large remote fetches and heavier regex passes can feel slow on low-power ARM boards. |
| NullClaw | partial | Read-only inspection is conceptually safe, but some NullClaw images omit Python or outbound HTTP support for remote scans. |
| NanoBot | full | Strong choice for wrapping the JSON findings into conversational approval flows without changing the source skill. |
| IronClaw | full | Sandboxed execution is enough because the scanner only reads text and emits local findings. |
    
