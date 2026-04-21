# ClawForge variant guide

ClawForge targets six Claw variants with explicit compatibility metadata on every skill.

## Variant overview

| Variant | Runtime | Typical strengths | Common limits |
| --- | --- | --- | --- |
| OpenClaw | TypeScript / Node.js | Desktop workflows, broad tool support | Higher memory footprint |
| ZeroClaw | Rust | Efficient production workflows on small servers | Smaller ecosystem footprint |
| PicoClaw | Go | Lightweight deployment and SBC use cases | Limited long-running automation capacity |
| NullClaw | Zig | Ultra-small, embedded deployments | Minimal shell/runtime access |
| NanoBot | Python | Research, ML, and scripting-heavy flows | Larger Python/runtime requirements |
| IronClaw | TypeScript + WASM | Sandboxed enterprise execution | Restricted shell and network access |

## Install targets

By default, ClawForge installs skills into per-variant directories:

| Variant | Target path |
| --- | --- |
| OpenClaw | `~/.openclaw/skills` |
| ZeroClaw | `~/.zeroclaw/skills` |
| PicoClaw | `~/.picoclaw/skills` |
| NullClaw | `~/.nullclaw/skills` |
| NanoBot | `~/.nanobot/skills` |
| IronClaw | `~/.ironclaw/skills` |

## Reading compatibility levels

- `full` — supported as written
- `partial` — useful but constrained on this variant
- `unsupported` — do not install or run on this variant

## Current flagship catalog

Run the validator to print the live matrix:

```bash
python3 tools/validate_skills.py --markdown-table
```

This keeps the guide aligned with the actual checked-in skill metadata instead of duplicating compatibility data manually.
