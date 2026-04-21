# Contributing to ClawForge

ClawForge accepts contributions that improve the shared skill catalog, repository tooling, documentation, or compatibility coverage across the Claw ecosystem.

## Skill authoring standard

Every skill lives in `skills/<skill-name>/` and should include:

- `SKILL.md` with ClawForge frontmatter and a runbook-style body
- `README.md` for human-oriented context and examples
- `COMPAT.md` with variant-specific notes
- `install.sh` when setup is needed
- `scripts/` for executable helpers used by the skill

## Required frontmatter

Each `SKILL.md` must define:

- `name`
- `description`
- `version`
- `metadata.openclaw.emoji`
- `metadata.openclaw.requires.bins`
- `metadata.openclaw.requires.env`
- `metadata.openclaw.compat` for all six supported variants
- `metadata.openclaw.security_tier`
- `metadata.openclaw.tags`

Reference the canonical schema in [`docs/skill-format.md`](docs/skill-format.md).

## Compatibility expectations

Do not guess at compatibility. Use:

- `full` when the skill works as written
- `partial` when some steps or integrations are unavailable
- `unsupported` when the variant cannot safely execute the workflow

Explain partial or unsupported cases in `COMPAT.md`.

## Security review expectations

- Use the lowest correct security tier.
- Document every required binary and environment variable.
- Avoid `curl | sh`, opaque payloads, silent network exfiltration, or hidden credential reads.
- Treat L3 skills as human-reviewed changes; they should be easy to audit and explicit about their blast radius.

## Development workflow

1. Scaffold new skills with `./tools/forge-skill.sh`.
2. Keep metadata and compatibility notes in sync.
3. Run local checks before opening a PR:

   ```bash
   bash -n install.sh install-skill.sh tools/forge-skill.sh tools/skill-lib.sh
   python3 tools/validate_skills.py
   ```

4. Open a focused PR with a clear summary of compatibility and security impact.

## Pull request checklist

- Skill metadata is complete and valid
- `COMPAT.md` explains any `partial` or `unsupported` statuses
- Any L3 skill change is clearly marked for human review
- Examples in `README.md` match the actual runbook
- New scripts are executable and shell-safe
