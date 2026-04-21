---
name: docker-hygiene
description: Docker resource auditor for dangling images, containers, and volumes.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🐳"
    requires:
      bins: ["docker", "jq", "awk"]
      env: ["DOCKER_HOST"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: full
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["devops", "docker", "cleanup", "containers"]
---

# docker-hygiene

## Purpose

Docker resource auditor for dangling images, containers, and volumes.

## Runbook

1. Run `scripts/audit.sh` to collect dangling images, exited containers, unused volumes, and total disk usage.
2. Review the JSON output in `docker-audit.json` and inspect each category before recommending cleanup.
3. If the operator wants to prune, run `scripts/prune.sh --dry-run` first to preview what would be removed.
4. Only run `scripts/prune.sh --force` after explicit operator approval.
5. Run `scripts/report.sh` to generate a markdown cost-digest summary.

## Stop conditions

1. Abort if `docker` is not running (`docker info` fails).
2. Abort if the Docker daemon is unreachable.
3. Never run `docker system prune` without explicit `--force` confirmation; default mode is dry-run.
4. Abort if the active variant is unsupported.

## Output format

- `docker-audit.json` — structured audit with dangling images, exited containers, unused volumes, and disk usage
- Console: markdown cost-digest with prune savings estimate

## Example invocations

- `bash skills/docker-hygiene/scripts/audit.sh`
- `bash skills/docker-hygiene/scripts/prune.sh --dry-run`
- `bash skills/docker-hygiene/scripts/report.sh`
- "Audit my Docker environment and show me what's safe to clean up."
