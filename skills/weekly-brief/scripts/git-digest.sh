#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "weekly-brief git-digest: git is required." >&2
  exit 1
fi

REPO_LIST_VALUE="${REPO_LIST:-}"
REPO_LIST_VALUE="$REPO_LIST_VALUE" python3 - <<'PY'
import json
import os
import pathlib
import subprocess

repo_list = [item for item in os.environ.get("REPO_LIST_VALUE", "").split() if item]
results = []

for repo in repo_list:
    repo_path = pathlib.Path(repo).expanduser()
    if not repo_path.exists():
        print(f"weekly-brief git-digest: repo not found, skipping: {repo_path}", file=os.sys.stderr)
        continue
    repo_check = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    if repo_check.returncode != 0 or repo_check.stdout.strip() != "true":
        print(f"weekly-brief git-digest: not a git repo, skipping: {repo_path}", file=os.sys.stderr)
        continue
    completed = subprocess.run(
        [
            "git", "-C", str(repo_path), "--no-pager", "log",
            "--since=7 days ago",
            "--date=iso-strict",
            "--pretty=format:%H%x1f%ad%x1f%s",
        ],
        capture_output=True,
        text=True,
    )
    commits = []
    if completed.returncode == 0 and completed.stdout.strip():
        for line in completed.stdout.splitlines():
            commit_hash, commit_date, message = line.split("\x1f", 2)
            commits.append({"hash": commit_hash[:12], "message": message, "date": commit_date})
    results.append({"repo": str(repo_path), "commits": commits})

print(json.dumps(results, indent=2))
PY
