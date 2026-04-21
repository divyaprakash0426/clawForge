#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--mock" ]; then
  cat <<'EOF'
{
  "dangling_images": {
    "count": 2,
    "ids": ["sha256:111111", "sha256:222222"],
    "items": [
      {"id": "sha256:111111", "repository": "<none>", "tag": "<none>", "size": "245MB"},
      {"id": "sha256:222222", "repository": "<none>", "tag": "<none>", "size": "118MB"}
    ]
  },
  "exited_containers": {
    "count": 2,
    "names": ["nightly-build", "old-api"],
    "items": [
      {"id": "abc123", "name": "nightly-build", "status": "Exited (0) 2 days ago"},
      {"id": "def456", "name": "old-api", "status": "Exited (137) 5 days ago"}
    ]
  },
  "unused_volumes": {
    "count": 1,
    "names": ["postgres-cache"],
    "items": [
      {"name": "postgres-cache", "driver": "local"}
    ]
  },
  "disk_usage": [
    {"type": "Images", "total_count": "14", "active": "5", "size": "6.4GB", "reclaimable": "2.8GB (43%)"},
    {"type": "Containers", "total_count": "9", "active": "3", "size": "412MB", "reclaimable": "201MB (48%)"},
    {"type": "Local Volumes", "total_count": "4", "active": "2", "size": "1.9GB", "reclaimable": "740MB (38%)"}
  ]
}
EOF
  exit 0
fi

for bin in docker jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "docker-hygiene requires $bin." >&2
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running or is unreachable." >&2
  exit 1
fi

dangling_images="$(docker images -f dangling=true --format '{{json .}}' | jq -cs 'map({id: (.ID // ""), repository: (.Repository // ""), tag: (.Tag // ""), size: (.Size // "")})')"
exited_containers="$(docker ps -a -f status=exited --format '{{json .}}' | jq -cs 'map({id: (.ID // ""), name: (.Names // ""), status: (.Status // "")})')"
unused_volumes="$(docker volume ls -f dangling=true --format '{{json .}}' | jq -cs 'map({name: (.Name // ""), driver: (.Driver // "")})')"

if docker system df --format '{{json .}}' >/dev/null 2>&1; then
  disk_usage="$(docker system df --format '{{json .}}' | jq -cs 'map({type: (.Type // .TYPE // ""), total_count: (.TotalCount // .TOTALCOUNT // .Total // ""), active: (.Active // ""), size: (.Size // ""), reclaimable: (.Reclaimable // "")})')"
else
  disk_usage="$(docker system df | tail -n +2 | sed -E 's/[[:space:]]{2,}/|/g' | jq -Rsc 'split("\n") | map(select(length > 0)) | map(split("|")) | map({type: (.[0] // ""), total_count: (.[1] // ""), active: (.[2] // ""), size: (.[3] // ""), reclaimable: (.[4] // "")})')"
fi

jq -n           --argjson images "$dangling_images"           --argjson containers "$exited_containers"           --argjson volumes "$unused_volumes"           --argjson disk "$disk_usage"           '{
    dangling_images: {
      count: ($images | length),
      ids: ($images | map(.id)),
      items: $images
    },
    exited_containers: {
      count: ($containers | length),
      names: ($containers | map(.name)),
      items: $containers
    },
    unused_volumes: {
      count: ($volumes | length),
      names: ($volumes | map(.name)),
      items: $volumes
    },
    disk_usage: $disk
  }'
