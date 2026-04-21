#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "kube-scout requires python3." >&2
  exit 1
fi

if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "kube-scout requires PyYAML (python3 -m pip install pyyaml)." >&2
  exit 1
fi

echo "kube-scout dependencies look available."
