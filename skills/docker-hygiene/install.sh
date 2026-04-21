#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in docker jq; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[ok] $bin"
  else
    echo "[missing] $bin"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "docker-hygiene requires docker and jq." >&2
  exit 1
fi

if docker info >/dev/null 2>&1; then
  if [ -n "${DOCKER_HOST:-}" ]; then
    echo "[ok] docker daemon reachable via DOCKER_HOST=${DOCKER_HOST}"
  else
    echo "[ok] docker daemon reachable"
  fi
else
  echo "[error] Docker daemon is not running or is unreachable." >&2
  exit 1
fi
