#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prune.sh [--dry-run] [--force]

Preview or remove dangling images, exited containers, and unused volumes.
Dry-run is the default. Use --force to perform the targeted prune actions.
EOF
}

mode="dry-run"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      mode="dry-run"
      shift
      ;;
    --force)
      mode="force"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker-hygiene requires docker." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running or is unreachable." >&2
  exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
audit_json="$($SCRIPT_DIR/audit.sh)"

image_count="$(jq '.dangling_images.count' <<<"$audit_json")"
container_count="$(jq '.exited_containers.count' <<<"$audit_json")"
volume_count="$(jq '.unused_volumes.count' <<<"$audit_json")"

if [ "$mode" = "dry-run" ]; then
  echo "Dry run only. Re-run with --force to remove these resources."
  echo "Would remove: images=$image_count exited_containers=$container_count unused_volumes=$volume_count"
  exit 0
fi

docker image prune -f >/dev/null
docker container prune -f >/dev/null
docker volume prune -f >/dev/null

echo "Removed: images=$image_count exited_containers=$container_count unused_volumes=$volume_count"
