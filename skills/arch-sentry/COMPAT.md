# Compatibility notes for arch-sentry

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Native Linux shell access makes pacman queries, `/etc` scans, and approval-gated remediation guidance practical on real Arch hosts. |
| ZeroClaw | full | Works well when ZeroClaw is attached to an Arch or Arch ARM system and can inspect package metadata locally. |
| PicoClaw | partial | Raspberry Pi ARM boards typically run Raspberry Pi OS (Debian-based), not Arch; this skill is useful only if Arch ARM is actually installed. |
| NullClaw | unsupported | NullClaw targets do not expose pacman state or `/etc` drift in a way this skill can safely audit. |
| NanoBot | full | Strong fit for turning the raw audit JSON into a concise operator digest while leaving any privileged cleanup to the human. |
| IronClaw | partial | Sandboxed runners can summarize saved audit output, but direct pacman access and `/etc` inspection are often blocked. |
    
