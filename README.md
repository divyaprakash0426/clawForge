# ClawForge

ClawForge is a curated, cross-variant-compatible skill hub for the Claw ecosystem. It ships **30 battle-tested skills**, a shared `SKILL.md` standard, security-first review patterns, persona packs (`souls/`), and scaffolding tooling — the everything-claude-code moment for the full Claw variant landscape.

> 📰 Read the design rationale: [Why the Claw ecosystem needs a skill commons](docs/dev-article-draft.md)

## Why ClawForge

- **Cross-variant by default**: every skill declares explicit compatibility for OpenClaw, ZeroClaw, PicoClaw, NullClaw, NanoBot, and IronClaw.
- **Curated over noisy**: ClawHub hosts 13,729 skills; ~20% are flagged as low-quality or risky (ClawHavoc, 2026). ClawForge is the battle-tested alternative.
- **Security-first**: each skill carries a permission tier (L1–L3), dependency declaration, and compatibility notes. `skill-sentinel` scans skills for risky patterns before installation.
- **Souls support**: `souls/` ships persona packs that layer operator context on top of the skill catalog — security operator, research analyst, DevOps engineer.
- **Contributor-friendly**: `tools/forge-skill.sh` scaffolds new skills with the standard directory layout and metadata schema in under a minute.

## One-command install

```bash
./install.sh
```

Useful flags:

```bash
./install.sh --list
./install.sh --all
./install.sh --skills arch-sentry,skill-sentinel
./install.sh --variant zeroclaw
```

Install a single skill directly:

```bash
./install-skill.sh arch-sentry
```

## Variant matrix

| Variant | Primary runtime | Typical install target |
| --- | --- | --- |
| OpenClaw | TypeScript / Node.js | `~/.openclaw/skills` |
| ZeroClaw | Rust | `~/.zeroclaw/skills` |
| PicoClaw | Go | `~/.picoclaw/skills` |
| NullClaw | Zig | `~/.nullclaw/skills` |
| NanoBot | Python | `~/.nanobot/skills` |
| IronClaw | TypeScript + WASM | `~/.ironclaw/skills` |

See [`docs/variant-guide.md`](docs/variant-guide.md) for the full compatibility notes.

## Skill catalog

30 skills across 7 domains. All skills declare explicit per-variant compatibility in their `SKILL.md` frontmatter and `COMPAT.md`.

### DevOps & Infrastructure

| Skill | Summary |
| --- | --- |
| `arch-sentry` | Arch Linux health audits for pacman cache, orphan packages, and pacnew drift. |
| `tf-copilot` | Terraform plan interpretation with compliance-aware fix suggestions. |
| `docker-hygiene` | Container/image/volume cleanup audits and weekly hygiene reporting. |
| `aws-cost-watcher` | Daily AWS spend anomaly watcher with Bedrock cost correlation. |
| `kube-scout` | Kubernetes manifest auditor for unsafe defaults, missing limits, and weak image pinning. |
| `dep-hygiene` | Dependency manifest inspector for missing lockfiles, loose pins, and risky git/path sources. |
| `changelog-weaver` | Turn git history into release-note sections grouped by conventional commit intent. |
| `ci-logbook` | Summarize CI logs into high-signal failures, warnings, and likely next actions. |

### Security & Safety

| Skill | Summary |
| --- | --- |
| `skill-sentinel` | Pre-install scan for prompt injection, exfiltration patterns, and risky shell usage. |
| `secret-guard` | Secret scanning wrapper for repos and skill configs. |
| `permission-lens` | Human-readable permission manifest and risk explanation for any skill. |
| `prompt-fence` | Scan prompt and instruction files for jailbreak phrases, exfiltration cues, and unsafe shell patterns. |

### Research & Knowledge Work

| Skill | Summary |
| --- | --- |
| `arxiv-scout` | Monitors arXiv for agentic AI and MCP papers and syncs structured notes. |
| `bedrock-rag` | Indexes local markdown into a Bedrock-backed retrieval workflow. |
| `deep-cite` | Source-first research workflow with explicit claims and citations. |
| `repo-radar` | Generate a compact repository briefing from manifests, workflows, docs, and source layout. |

### Productivity

| Skill | Summary |
| --- | --- |
| `weekly-brief` | Compiles a weekly digest from git history, PRs, calendars, and logbooks. |
| `inbox-zero` | Email triage assistant for labels, drafts, and priority escalation. |
| `focus-block` | Pomodoro-aware focus session manager with DND and journal logging. |
| `meeting-prep` | Pre-meeting agenda and notes briefing generator. |

### Health, Sports & Fitness

| Skill | Summary |
| --- | --- |
| `coach-claw` | Badminton training planner with tournament and recovery context. |
| `lift-log` | Structured workout logger with progressive overload tracking. |
| `recovery-ai` | Rolling-load recovery guidance driven by workout and HRV signals. |
| `hydration-check` | Summarize water-intake logs and flag low-intake streaks against a daily target. |

### Creative & Media

| Skill | Summary |
| --- | --- |
| `shorts-forge` | AutoShorts-style pipeline from script to rendered MP4 output. |
| `blog-pipeline` | Draft-to-publish blog pipeline with markdown-first publishing targets. |
| `thumbnail-lab` | Turn a short script into reusable thumbnail hooks, overlay copy, and shot prompts. |

### Finance & Analytics

| Skill | Summary |
| --- | --- |
| `portfolio-pulse` | Daily portfolio watcher for equities and crypto performance. |
| `expense-log` | Local-first expense categorizer for bank SMS and CSV exports. |
| `invoice-ledger` | Age invoice CSV exports into overdue buckets and cash-collection summaries. |

## Souls — persona packs

The `souls/` directory ships operator persona packs that layer context, tone, and domain assumptions on top of the skill catalog. A soul configures *how* your agent behaves across all skills — not what it can do.

See [`souls/README.md`](souls/README.md) for the schema and available packs.

Example packs included: `security-operator`, `research-analyst`, `devops-engineer`.

## Repository layout

```text
clawforge/
├── skills/                  # 30 skill directories following the ClawForge schema
├── souls/                   # Persona packs (SOUL.md + soul.yaml)
├── docs/                    # Format guides, variant guide, DEV article draft
├── tools/                   # Installer, validator, and scaffolding scripts
├── install.sh               # Multi-skill installer with variant detection
├── install-skill.sh         # Single-skill installer with compat check
└── .github/workflows/       # Lint, compatibility, and security automation
```

## Security philosophy

ClawForge treats the skill supply chain as adversarial. Skills are reviewed as code, not just prose:

1. Each `SKILL.md` includes an explicit permission tier (L1 read-only → L3 production/creds).
2. Runtime dependencies are declared in frontmatter — no implicit system access.
3. Compatibility is encoded per variant instead of assumed.
4. `skill-sentinel` is wired into the repository workflow and available as a local scanner.
5. `prompt-fence` scans instruction files for jailbreak and exfiltration patterns.

See [`SECURITY.md`](SECURITY.md) for reporting guidance and review expectations.

## Contributing

Follow the ClawForge skill schema and compatibility rules in [`CONTRIBUTING.md`](CONTRIBUTING.md). The fastest path to a valid skill:

```bash
./tools/forge-skill.sh
```

See [`docs/skill-format.md`](docs/skill-format.md) for the full `SKILL.md` spec.
