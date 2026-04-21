#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from collections import OrderedDict

SECTIONS = OrderedDict([
    ("feat", "Features"),
    ("fix", "Fixes"),
    ("perf", "Performance"),
    ("refactor", "Refactors"),
    ("docs", "Documentation"),
    ("test", "Tests"),
    ("build", "Build and CI"),
    ("ci", "Build and CI"),
    ("chore", "Maintenance"),
])


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def default_from_ref() -> str:
    try:
        return git("describe", "--tags", "--abbrev=0")
    except subprocess.CalledProcessError:
        return "HEAD~20"


def collect(start: str, end: str) -> list[tuple[str, str]]:
    raw = git("log", "--no-merges", "--pretty=format:%H%x09%s", f"{start}..{end}")
    commits = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        sha, subject = line.split("\t", 1)
        commits.append((sha, subject))
    return commits


def categorize(subject: str) -> str:
    prefix = subject.split(":", 1)[0].lower()
    prefix = prefix.split("(", 1)[0]
    return prefix if prefix in SECTIONS else "other"


def render(start: str, end: str, commits: list[tuple[str, str]]) -> str:
    grouped: dict[str, list[tuple[str, str]]] = {key: [] for key in list(SECTIONS) + ["other"]}
    for sha, subject in commits:
        grouped[categorize(subject)].append((sha, subject))
    lines = [f"# Changelog ({start}..{end})", ""]
    for key, title in list(SECTIONS.items()) + [("other", "Other")]:
        items = grouped[key]
        if not items:
            continue
        lines.extend([f"## {title}", ""])
        for sha, subject in items:
            lines.append(f"- {subject} ({sha[:7]})")
        lines.append("")
    if len(lines) == 2:
        lines.append("No commits found in the requested range.")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a draft changelog from git history.")
    parser.add_argument("--from", dest="start", default=None, help="Start ref (exclusive).")
    parser.add_argument("--to", dest="end", default="HEAD", help="End ref (inclusive).")
    args = parser.parse_args()

    start = args.start or default_from_ref()
    commits = collect(start, args.end)
    sys.stdout.write(render(start, args.end, commits))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
