# Why the Claw ecosystem needs a skill commons — and how I built one

> **DEV Challenge submission draft** — "Wealth of Knowledge" category.
> This essay accompanies the [ClawForge repository](https://github.com/modernyogi/clawForge).

---

## The supply chain problem nobody wants to talk about

ClawHub crossed 13,729 community-published skills in April 2026. That number sounds impressive until you learn that security researchers estimate roughly 20% of those skills contain patterns consistent with prompt injection, credential exfiltration, or unsafe shell execution. The ClawHavoc campaign made this concrete: a coordinated actor published ~300 skills across multiple Claw variants, each embedding a silent exfiltration hook behind an otherwise legitimate-looking system automation. Skills were installed by thousands of developers before the campaign was identified.

The root problem is structural. ClawHub operates like npm circa 2014: publish-and-forget, no manifest enforcement, no per-variant compatibility declaration, no permission tier labeling. When you `install` a skill, you are trusting a markdown file you've never read, written by someone you've never met, to run arbitrary shell commands with your agent's credentials.

ClawForge is my answer to that problem. It is not another skill list. It is a curated commons with an explicit trust model baked into the schema.

---

## The variant problem is bigger than it looks

Ask most OpenClaw developers which variants they target and you'll get a blank stare. But the variant landscape is genuinely fragmented:

| Variant | Runtime | Idle RAM | Key constraint |
| --- | --- | --- | --- |
| OpenClaw | TypeScript / Node.js | ~1.5 GB | Full feature set, desktop only |
| ZeroClaw | Rust | ~7.8 MB | Production VPS, low resource |
| PicoClaw | Go | < 10 MB | Raspberry Pi, $10 boards |
| NullClaw | Zig | ~1 MB | RISC-V, ultra-embedded |
| NanoBot | Python | ~100 MB | AI research, ML workflows |
| IronClaw | TypeScript + WASM | Standard | High-security enterprise sandbox |

A skill that calls `curl | bash` works fine on OpenClaw. It will silently fail or be blocked entirely on NullClaw. A skill that requires `aws-cli` in PATH is useless on a PicoClaw board. A skill that writes to `~/.config` may violate the IronClaw sandbox policy.

No existing skill collection tracks this. ClawForge's `SKILL.md` frontmatter requires every skill to declare a per-variant compatibility value — `full`, `partial`, or `unsupported` — and document the reason for any non-`full` status in a `COMPAT.md` file. This makes the compatibility matrix machine-readable: the installer filters skills automatically for the detected variant.

---

## What ClawHavoc actually taught us

The ClawHavoc campaign followed a pattern security researchers call a "trojan commons" attack. The attacker published genuinely useful skills — a Docker cleanup tool, an AWS cost monitor, a git log formatter — each with a payload buried in a post-install hook or an obfuscated eval block inside a `run.sh`. Because the skills were useful, they accumulated real installs. Because ClawHub had no automated scanning, the payload ran undetected for weeks on developer machines with active AWS, GitHub, and Telegram credentials in the environment.

Three lessons:

1. **Usefulness and safety are orthogonal.** A trojan skill can be more useful than a clean one. Utility alone is not a trust signal.
2. **Schema enforcement is a prerequisite for trust.** If the format is loose enough to hide a payload, it will be used to hide a payload.
3. **Defense has to be part of the install path.** A scanner that runs after installation catches nothing.

ClawForge responds to all three. Every skill in the catalog has been authored with explicit permission tiers. `skill-sentinel` runs as a GitHub Actions workflow on every pull request and is available as a local pre-install scanner. `prompt-fence` extends this to instruction and soul files. `secret-guard` covers committed secrets in skill configs. The security primitives are not opt-in — they're part of the repository CI.

---

## The China signal: what the underground market proved

In early 2026, reports emerged of Chinese developers selling "AI skill packs" for OpenClaw and QClaw on secondary markets, with bundles trading for tens of thousands of RMB. Tencent responded by launching QClaw with 5,000 prebuilt skills and a three-minute deployment story. The pattern was striking: there was clearly enormous appetite for **batteries-included, domain-specific skill bundles** that a non-technical user could drop in and use immediately.

No English-language equivalent existed. The closest thing was Andrej Karpathy's personal skill repo — credible and well-reasoned, but intentionally narrow. `everything-claude-code` showed that a complete, production-tested system beats a list every time (46K+ stars, Anthropic hackathon winner). But neither project addressed the variant landscape or the supply chain problem.

ClawForge is the legitimate, open-source, English-language answer to the demand signal the underground market proved. Thirty skills across seven domains, installable in one command, with explicit compatibility metadata and a security scanner in the CI pipeline.

---

## The AgentSkills portability problem

The emerging AgentSkills spec promises cross-agent skill portability: a skill authored once should be usable by OpenClaw, NullClaw, and a hypothetical future variant that doesn't exist yet. The promise is real. The current implementation has gaps.

The biggest gap is capability negotiation. The spec defines a skill's *interface* but not its *execution requirements*. A skill that requires a 1.5 GB Node.js runtime to evaluate can declare itself AgentSkills-compatible while being completely unusable on a NullClaw device. Portability at the interface level without portability at the execution level creates a false sense of compatibility.

ClawForge's `COMPAT.md` pattern is a practical interim solution. It doesn't replace the spec — it augments it with the ground truth that the spec doesn't yet capture: which variants actually run this skill, what breaks on partial variants, and what the operator needs to know before installing on a constrained device.

---

## Design decisions and trade-offs

**Why 30 skills instead of 300?** Curation is the product. ClawHub already has 13,729 entries. Adding to the noise isn't useful. The 30 flagship skills were selected for genuine usefulness across developer/power-user personas, cross-variant compatibility where possible, and coverage of gaps not well-addressed by existing ClawHub entries. Each skill is authored to production standards, not scaffolded and abandoned.

**Why a static security tier instead of a dynamic risk score?** Dynamic scoring invites gaming. A skill author can rewrite a risky shell call to avoid pattern detection. A static permission tier declared by the author and reviewed by a maintainer is harder to fake — it creates a paper trail and puts accountability on the contributor.

**Why `souls/` in the same repo?** Persona packs are not separate from skills — they shape how skills behave. A security operator running `skill-sentinel` should get terse, actionable output. A research analyst running `arxiv-scout` should get structured summaries with citation context. Shipping persona packs alongside the skill catalog makes the behavioral contract explicit.

**Why not build on top of ClawHub's existing infrastructure?** Because the problem is the infrastructure. ClawHub's permissive publish model is the attack surface. ClawForge is designed to be a curated alternative that coexists with ClawHub, not a replacement for it. The install tooling is intentionally local-first and format-verified.

---

## What comes next

ClawForge is a foundation, not a finished product. The work that matters next:

- **Per-variant install test matrix**: automated CI that actually runs a representative skill on each variant in a sandboxed container and reports pass/fail against the declared compatibility.
- **Soul-to-skill binding**: a mechanism to declare which skills a persona pack activates by default, reducing per-session configuration friction.
- **Community skill review queue**: a structured contribution path with security checklist, reviewer assignment, and automated `skill-sentinel` gate — analogous to a software package maintainer model.
- **Locale packs**: the demand signal from the China market is real. Non-English skill bodies and locale-adapted persona packs would unlock a substantial user base.

The commons model only works if it stays curated. That means saying no to volume for the sake of volume, enforcing the schema, and treating every new skill as a potential attack surface until proven otherwise.

That's the bet ClawForge makes.

---

*ClawForge is open source. Contributions follow the schema in [`CONTRIBUTING.md`](../CONTRIBUTING.md) and the skill format in [`docs/skill-format.md`](skill-format.md).*
