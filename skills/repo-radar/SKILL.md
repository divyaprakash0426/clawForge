---
name: repo-radar
description: Generate a compact repository briefing from manifests, workflows, docs, and source layout.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📚"
    requires:
      bins: ['python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: partial
      nanobot: full
      ironclaw: full
    security_tier: L1
    tags: ['research', 'repository', 'onboarding', 'inventory']
---

# repo-radar

## Purpose

Produce a fast onboarding brief for an unfamiliar codebase without making changes.

## Runbook

1. Run the skill at the repository root or a scoped subdirectory.
2. Use `scripts/brief.py` to inventory manifests, workflows, docs, tests, and dominant file types.
3. Read the generated brief before deeper exploration so you can choose the right next tool.
4. Treat the result as a map of likely hotspots, not as a substitute for targeted code review.

## Stop conditions

1. Abort if the repository tree is too incomplete to represent the project accurately.
2. Abort before drawing security or architecture conclusions from filename patterns alone.
3. Abort if the active variant cannot safely scan the requested directory.

## Output format

- Markdown or JSON repository briefing
- Detected manifests and workflow files
- Top file extensions and test coverage hints

## Example invocations

- `python3 skills/repo-radar/scripts/brief.py . --markdown`
- `python3 skills/repo-radar/scripts/brief.py services/backend`
