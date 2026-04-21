# Security Policy

ClawForge treats skills as executable supply-chain artifacts. The repository is designed to make permissions, dependencies, and compatibility visible before a skill is installed.

## Reporting a vulnerability

If you find a vulnerability in a skill, installer, or repository workflow:

1. Do not open a public issue with exploit details.
2. Share the affected paths, impact, and reproduction notes privately with the maintainers.
3. Include whether the issue can lead to credential access, code execution, hidden network access, or data destruction.

## Review principles

- **Explicit permissions**: every skill declares a security tier.
- **Declared dependencies**: required binaries and environment variables live in frontmatter.
- **No hidden side effects**: install scripts and helper scripts should be easy to audit.
- **Compatibility transparency**: unsupported variants are marked instead of failing later at runtime.

## Security tiers

| Tier | Meaning | Typical examples |
| --- | --- | --- |
| `L1` | Read-only or low-risk local inspection | Reporting, summarization, linting |
| `L2` | Local writes or automation with bounded impact | Draft generation, local file updates |
| `L3` | Production credentials, infrastructure changes, or privileged actions | Cloud changes, message delivery, secret access |

## What `skill-sentinel` checks

The bundled `skill-sentinel` skill is meant to flag common risk indicators:

- prompt injection markers
- suspicious shell pipelines
- outbound fetches to raw IPs
- credential-oriented environment variable reads
- encoded payload execution patterns

It is a review aid, not a substitute for human inspection.

## Hardening guidance for contributors

- Prefer explicit commands over dynamically constructed shells.
- Avoid downloading and executing remote content during install.
- Make network usage obvious in the runbook.
- Explain required secrets in `README.md` and frontmatter.
- Keep L3 skills narrow and auditable.
