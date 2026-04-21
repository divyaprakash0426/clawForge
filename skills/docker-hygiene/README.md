# docker-hygiene

## What it does

`docker-hygiene` audits a Docker host for stale objects that are usually safe to review for cleanup: dangling images, exited containers, unused volumes, and disk-usage hot spots from `docker system df`.

## Quick start

```bash
bash skills/docker-hygiene/scripts/audit.sh > docker-audit.json
bash skills/docker-hygiene/scripts/report.sh
bash skills/docker-hygiene/scripts/prune.sh --dry-run
```

## Sample output

```json
{
  "dangling_images": {"count": 2, "ids": ["sha256:111", "sha256:222"]},
  "exited_containers": {"count": 3, "names": ["nightly-build", "debug-shell", "old-api"]},
  "unused_volumes": {"count": 1, "names": ["postgres-cache"]}
}
```

## Safety notes

- `prune.sh` defaults to preview mode; nothing is removed unless `--force` is provided.
- The skill never calls `docker system prune`; it only uses targeted image / container / volume prune commands.
- Set `DOCKER_HOST` when the daemon lives on a remote socket or TCP endpoint.
- If you only want a report, run `audit.sh` and `report.sh` without any prune step.
