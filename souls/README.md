# Souls — ClawForge persona packs

A **soul** is an operator persona that layers behavioral context on top of the skill catalog. It configures *how* your agent responds and prioritizes — not what skills it can load.

Souls are intentionally thin. They don't replicate skill logic. They set defaults: tone, output format, which skills to activate on startup, domain-specific vocabulary, and stop conditions appropriate for the operator's context.

---

## Schema

Each soul lives in its own subdirectory under `souls/`:

```text
souls/
└── <soul-name>/
    ├── SOUL.md       ← behavior spec (required)
    └── soul.yaml     ← machine-readable metadata (required)
```

### `soul.yaml` frontmatter

```yaml
name: security-operator          # kebab-case identifier
display_name: Security Operator  # human-readable label
version: 1.0.0
author: clawforge-maintainers
domain: security                 # primary domain (devops|security|research|productivity|health|creative|finance)
tone: terse                      # terse | balanced | verbose
activate_skills:                 # skills to load on session start
  - skill-sentinel
  - secret-guard
  - permission-lens
  - prompt-fence
preferred_output: structured     # structured | prose | raw
security_tier_cap: L2            # refuse skill activations above this tier without explicit confirmation
tags: [security, secops, supply-chain, audit]
compat:                          # inherits from activated skills; document overrides here
  openclaw: full
  zeroclaw: full
  picoclaw: partial
  nullclaw: unsupported
  nanobot: full
  ironclaw: full
```

### `SOUL.md` body conventions

1. **Identity** — one paragraph describing the operator context and perspective.
2. **Default behaviors** — bullet list of always-on behaviors (output format, verbosity, confirmation gates).
3. **Activated skills** — which ClawForge skills this soul turns on and why.
4. **Domain vocabulary** — terms and abbreviations the agent should use fluently.
5. **Stop conditions** — when the agent should pause and confirm before acting.
6. **Example invocations** — 2–3 annotated prompts showing the soul in practice.

---

## Field reference

| Field | Required | Notes |
| --- | --- | --- |
| `name` | Yes | Lowercase kebab-case. Must match directory name. |
| `display_name` | Yes | Human-facing label shown in UIs. |
| `version` | Yes | Semver string. |
| `domain` | Yes | Primary domain from the fixed list. |
| `tone` | Yes | `terse` (minimal prose, structured output), `balanced`, or `verbose` (explanatory). |
| `activate_skills` | Yes | Non-empty list of ClawForge skill names to load on start. |
| `preferred_output` | Yes | `structured` (tables/JSON), `prose` (narrative), or `raw` (unformatted). |
| `security_tier_cap` | Recommended | Prevents accidental L3 activations without confirmation. Defaults to `L3` (no cap). |
| `tags` | Yes | Non-empty list for catalog search. |
| `compat` | Yes | Per-variant compatibility. Inherit from most restrictive activated skill unless overridden. |

---

## Available packs

| Soul | Domain | Tone | Activated skills |
| --- | --- | --- | --- |
| [`security-operator`](security-operator/) | Security | Terse | skill-sentinel, secret-guard, permission-lens, prompt-fence |
| [`research-analyst`](research-analyst/) | Research | Balanced | arxiv-scout, bedrock-rag, deep-cite, repo-radar |
| [`devops-engineer`](devops-engineer/) | DevOps | Terse | arch-sentry, docker-hygiene, kube-scout, ci-logbook, dep-hygiene |

---

## Installing a soul

Souls are loaded via the `--soul` flag in the installer or manually copied to your variant's skills directory:

```bash
./install.sh --soul security-operator
./install.sh --soul research-analyst --variant nanobot
```

A soul file must be loaded before the skills it activates. The installer handles ordering automatically.

---

## Contributing a soul

1. Run `./tools/forge-skill.sh` and choose `soul` when prompted for type — it scaffolds the directory.
2. Fill in `soul.yaml` and `SOUL.md` following the schema above.
3. Only reference skills that exist in the ClawForge catalog (or note them as external dependencies).
4. Keep the behavior spec operational. Avoid motivational framing or marketing language.
5. Open a PR. CI will validate the `soul.yaml` frontmatter using the same linter as skills.

