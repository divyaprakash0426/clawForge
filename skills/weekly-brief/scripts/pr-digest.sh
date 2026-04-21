#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "weekly-brief pr-digest: GITHUB_TOKEN is unset; skipping merged PR lookup." >&2
  printf '[]\n'
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "weekly-brief pr-digest: gh is required." >&2
  exit 1
fi

REPO_LIST_VALUE="${REPO_LIST:-}"
GITHUB_TOKEN="$GITHUB_TOKEN" REPO_LIST_VALUE="$REPO_LIST_VALUE" python3 - <<'PY'
import datetime as dt
import json
import os
import pathlib
import re
import subprocess

cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=7)
repo_list = [item for item in os.environ.get("REPO_LIST_VALUE", "").split() if item]
results = []


def normalize_remote(remote: str) -> str | None:
    remote = remote.strip()
    match = re.search(r"github\.com[:/](.+?)(?:\.git)?$", remote)
    return match.group(1) if match else None


for repo in repo_list:
    repo_path = pathlib.Path(repo).expanduser()
    repo_check = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    if repo_check.returncode != 0 or repo_check.stdout.strip() != "true":
        continue
    remote = subprocess.run(
        ["git", "-C", str(repo_path), "--no-pager", "remote", "get-url", "origin"],
        capture_output=True,
        text=True,
    )
    remote_name = normalize_remote(remote.stdout) if remote.returncode == 0 else None
    if not remote_name:
        print(f"weekly-brief pr-digest: could not parse origin for {repo_path}", file=os.sys.stderr)
        continue
    completed = subprocess.run(
        [
            "gh", "pr", "list",
            "--state", "merged",
            "--limit", "20",
            "--json", "number,title,mergedAt,url",
            "--repo", remote_name,
        ],
        capture_output=True,
        text=True,
        env={**os.environ, "GH_TOKEN": os.environ["GITHUB_TOKEN"]},
    )
    if completed.returncode != 0:
        print(f"weekly-brief pr-digest: gh query failed for {remote_name}: {completed.stderr.strip()}", file=os.sys.stderr)
        continue
    prs = []
    for pr in json.loads(completed.stdout or "[]"):
        merged_at = pr.get("mergedAt")
        if not merged_at:
            continue
        merged_dt = dt.datetime.fromisoformat(merged_at.replace("Z", "+00:00"))
        if merged_dt >= cutoff:
            prs.append(pr)
    results.append({"repo": str(repo_path), "remote": remote_name, "pull_requests": prs})

print(json.dumps(results, indent=2))
PY
