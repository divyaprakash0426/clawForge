# Compatibility notes for docker-hygiene

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Ideal when the runtime has direct access to the local Docker socket and can inspect host disk usage. |
| ZeroClaw | full | Works well against local or remote daemons, especially when `DOCKER_HOST` is already configured for CI or ops hosts. |
| PicoClaw | full | Still useful on lightweight edge nodes running containers, though large prune previews may be slower on low-end storage. |
| NullClaw | unsupported | NullClaw targets do not expose a Docker daemon to audit or prune safely. |
| NanoBot | full | Great for turning audit JSON into a weekly cleanup digest while leaving prune approval to the operator. |
| IronClaw | partial | Sandboxed execution may allow report formatting but often blocks access to the Docker socket itself. |
