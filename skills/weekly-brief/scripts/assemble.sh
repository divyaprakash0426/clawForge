#!/usr/bin/env bash
set -euo pipefail

git_json_path="${1:-}"
pr_json_path="${2:-}"
logbook_json_path="${3:-}"

if [ -z "$git_json_path" ] || [ -z "$pr_json_path" ] || [ -z "$logbook_json_path" ]; then
  echo "usage: assemble.sh git.json pr.json logbook.json" >&2
  exit 1
fi

python3 - "$git_json_path" "$pr_json_path" "$logbook_json_path" <<'PY'
import json
import pathlib
import sys

git_data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
pr_data = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
logbook_data = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))

total_commits = sum(len(item.get("commits", [])) for item in git_data)
total_prs = sum(len(item.get("pull_requests", [])) for item in pr_data)
total_logs = len(logbook_data)

lines = ["# Weekly Brief", ""]
lines.extend(["## Git Activity", ""])
if git_data:
    for repo in git_data:
        lines.append(f"### {repo['repo']}")
        commits = repo.get("commits", [])
        if commits:
            for commit in commits:
                lines.append(f"- `{commit['hash']}` — {commit['message']} ({commit['date']})")
        else:
            lines.append("- No commits in the last 7 days.")
        lines.append("")
else:
    lines.extend(["- No repositories were processed.", ""])

lines.extend(["## Merged PRs", ""])
if pr_data:
    any_prs = False
    for repo in pr_data:
        lines.append(f"### {repo['remote']}")
        prs = repo.get("pull_requests", [])
        if prs:
            any_prs = True
            for pr in prs:
                lines.append(f"- [#{pr['number']}]({pr['url']}) {pr['title']} — merged {pr['mergedAt']}")
        else:
            lines.append("- No merged PRs in the last 7 days.")
        lines.append("")
    if not any_prs:
        lines.append("- No merged pull requests found across configured repositories.")
        lines.append("")
else:
    lines.extend(["- PR digest skipped or returned no data.", ""])

lines.extend(["## Logbook", ""])
if logbook_data:
    for entry in logbook_data:
        lines.append(f"### {entry['date']}")
        lines.append(entry["snippet"] or "No detail recorded.")
        lines.append("")
else:
    lines.extend(["- No logbook entries were included.", ""])

lines.extend(
    [
        "## Summary",
        "",
        f"- Total commits reviewed: {total_commits}",
        f"- Total merged PRs: {total_prs}",
        f"- Logbook entries included: {total_logs}",
    ]
)

print("\n".join(lines).rstrip() + "\n")
PY
