# Compatibility notes for blog-pipeline

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | `git`, `gh`, `pandoc`, `curl`, `jq` all available in standard desktop environments. Full pipeline supported. |
| ZeroClaw | full | All required binaries are installable in the ZeroClaw image. `pandoc` may require an explicit install step (see `install.sh`). |
| PicoClaw | partial | Lint and SEO-check scripts work on minimal hardware. Publishing via `gh` requires a network connection and sufficient RAM for the GitHub CLI. Not suitable for RPi Zero. |
| NullClaw | unsupported | No shell execution. Use the runbook manually to run each pipeline step on a capable host. |
| NanoBot | full | Python alternative for SEO check and uniqueness scan is straightforward. `gh` and `git` work normally. |
| IronClaw | partial | Outbound HTTPS to `api.github.com` and `dev.to` must be in the IronClaw network allowlist. `gh` binary must be in the exec allowlist. `GITHUB_TOKEN` and `DEVTO_API_KEY` must be injected via IronClaw's secrets mechanism, not plain env vars. |

