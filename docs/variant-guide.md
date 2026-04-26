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

## Cross-architecture evidence ladder

ClawForge should treat architecture support as staged proof instead of a boolean claim:

- `metadata-only` — `SKILL.md` / `COMPAT.md` declare support, but no installer or runtime path has been exercised on that ISA.
- `install-path-only` — the installer lands the expected files in the correct variant target path, but no representative skill has executed there yet.
- `emulated guest` — a guest OS for the target ISA boots and runs the host-safe lane end to end.
- `native device` — the same representative checks pass on physical hardware for that ISA.

The checked-in harness already defines the x86_64 baseline:

- `./.local/clawforge-vm/run-host-lane.sh` performs host-safe installer and mock execution checks.
- `./.local/clawforge-vm/bootstrap-e2e-vm.sh` provisions an amd64 Ubuntu guest and then calls `guest-runner.sh`.
- `guest-runner.sh` untars the repo in-guest and re-runs `run-host-lane.sh`, so guest evidence is a strict superset of copy-only install checks.

Because `bootstrap-e2e-vm.sh` currently defaults to `jammy-server-cloudimg-amd64.img`, x86_64 is the only ISA that can reach `emulated guest` with the checked-in tooling today.

## Recommended variant-to-hardware matrix

The table below defines the recommended proof floor before claiming real support for each variant / hardware class combination.

| Variant | Hardware / architecture class | Primary ISA targets | Recommended proof floor | Current representative skills |
| --- | --- | --- | --- | --- |
| OpenClaw | Full-runtime workstation / server | `x86_64`, `arm64` | `emulated guest` on `x86_64` and `arm64`; `metadata-only` elsewhere | `arch-sentry`, `skill-sentinel` |
| ZeroClaw | Efficient server / edge | `x86_64`, `arm64`, stretch `riscv64` | `emulated guest` on `x86_64` / `arm64`; `install-path-only` on `riscv64`; `metadata-only` on `i386` / `armv7` | `tf-copilot`, `permission-lens` |
| PicoClaw | Lightweight SBC / edge | `arm64`, `armv7`; secondary `x86_64`, `i386`, `riscv64` | `native device` on `armv7`; `emulated guest` on `arm64`; `install-path-only` on `x86_64` / `i386` / `riscv64` | `permission-lens`, `kube-scout` |
| NullClaw | Ultra-small embedded | `armv7`, `riscv64`; secondary `arm64` | `native device` on `armv7` / `riscv64`; `install-path-only` on `arm64` / `x86_64` / `i386` | `permission-lens`, `prompt-fence` |
| NanoBot | Python research / ML workstation | `x86_64`, `arm64` | `emulated guest` on `x86_64`; `native device` on `arm64`; `metadata-only` on `i386` / `armv7` / `riscv64` | `arxiv-scout` (`MOCK_MODE=1`), `deep-cite` install |
| IronClaw | Sandboxed WASM / enterprise | `x86_64`, `arm64`, stretch `riscv64` | `emulated guest` on `x86_64` / `arm64`; `install-path-only` on `riscv64`; `metadata-only` on `i386` / `armv7` | `permission-lens`, `deep-cite` install |

## Representative skills by architecture class

Use a small, stable set of skills per hardware class so the proof level stays understandable:

| Architecture class | Variants covered | Recommended skills | Why these checks anchor the class |
| --- | --- | --- | --- |
| Full-runtime 64-bit workstation / server | OpenClaw, ZeroClaw | `arch-sentry`, `tf-copilot`, `skill-sentinel` | Exercises installer paths plus shell-heavy, parser-heavy, and higher-dependency workflows. |
| Lightweight SBC / edge | PicoClaw | `permission-lens`, `kube-scout` | Keeps the lane Python-first and small-footprint while still proving useful real execution. |
| Ultra-small embedded | NullClaw | `permission-lens`, `prompt-fence` | Uses low-bin, read-mostly analyzers that fit constrained environments better than integration-heavy skills. |
| Research / ML workstation | NanoBot | `arxiv-scout` (`MOCK_MODE=1`) | Proves Python packaging, `curl` / `jq` integration, and writable local state without live network dependence. |
| Sandboxed / WASM enterprise | IronClaw | `permission-lens`, `deep-cite` install | Separates a fully safe manifest-style execution check from a broader install-path compatibility check. |

## Staged proof model by ISA

| ISA | What it should prove first | What graduates it | Release-quality proof |
| --- | --- | --- | --- |
| `x86_64` | `install-path-only` via `run-host-lane.sh` for all six variants | `emulated guest` via `bootstrap-e2e-vm.sh --suite full` | Optional `native device` spot checks; not required for routine gating because the local VM harness is already representative |
| `i386` | `install-path-only` for PicoClaw / NullClaw; keep OpenClaw / NanoBot / IronClaw at `metadata-only` | Optional `emulated guest` for PicoClaw control-lane coverage | `native device` only if ClawForge starts claiming active 32-bit operator support |
| `arm64` | `install-path-only` on an arm64 runner for OpenClaw, ZeroClaw, PicoClaw, NanoBot, IronClaw | `emulated guest` for OpenClaw / ZeroClaw / PicoClaw / IronClaw once an arm64 cloud image lane exists | `native device` for PicoClaw and NanoBot, where SBC quirks and Python packaging differences matter most |
| `armv7` | `install-path-only` for PicoClaw / NullClaw | Treat `emulated guest` as informative only | `native device` is the real gate for PicoClaw / NullClaw because constrained SBC behavior is the point of the target |
| `riscv64` | `metadata-only` first, then `install-path-only` for ZeroClaw / PicoClaw / NullClaw / IronClaw | Add `emulated guest` only for portable subsets | Require `native device` before advertising real NullClaw or PicoClaw support on `riscv64` |

In practice, the rollout order should be:

1. Keep `x86_64` as the reference lane with both host-safe and guest evidence.
2. Add `arm64` installer coverage first, then an arm64 guest lane.
3. Add `armv7` and `riscv64` as native-device lanes for PicoClaw / NullClaw before claiming more than install-path evidence.
4. Treat `i386` as a demand-driven compatibility lane, not a release blocker for the full catalog.

## Current flagship catalog

Run the validator to print the live matrix:

```bash
python3 tools/validate_skills.py --markdown-table
```

This keeps the guide aligned with the actual checked-in skill metadata instead of duplicating compatibility data manually.
