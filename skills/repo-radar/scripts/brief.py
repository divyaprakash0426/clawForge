#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from pathlib import Path

IGNORE_DIRS = {".git", "node_modules", ".venv", "venv", "dist", "build", "target", "__pycache__"}
MANIFEST_NAMES = {"package.json", "pyproject.toml", "Cargo.toml", "go.mod", "Dockerfile", "docker-compose.yml", "docker-compose.yaml", "Makefile"}
TEST_MARKERS = ("test", "spec")


def inventory(root: Path) -> dict:
    extension_counts: Counter[str] = Counter()
    manifests: list[str] = []
    docs: list[str] = []
    workflows: list[str] = []
    test_files = 0
    total_files = 0
    for current, dirs, files in os.walk(root):
        dirs[:] = [item for item in dirs if item not in IGNORE_DIRS]
        for name in files:
            path = Path(current) / name
            total_files += 1
            if name in MANIFEST_NAMES:
                manifests.append(str(path.relative_to(root)))
            if path.suffix.lower() in {".md", ".rst", ".txt"}:
                docs.append(str(path.relative_to(root)))
            if ".github/workflows" in str(path):
                workflows.append(str(path.relative_to(root)))
            stem = path.stem.lower()
            if any(marker in stem for marker in TEST_MARKERS):
                test_files += 1
            extension_counts[path.suffix.lower() or "[no extension]"] += 1
    return {
        "root": str(root.resolve()),
        "total_files": total_files,
        "manifests": sorted(manifests),
        "docs": sorted(docs)[:25],
        "workflows": sorted(workflows),
        "test_file_count": test_files,
        "top_extensions": extension_counts.most_common(10),
    }


def to_markdown(payload: dict) -> str:
    lines = ["# repo-radar brief", "", f"- Root: {payload['root']}", f"- Files: {payload['total_files']}", f"- Test-like files: {payload['test_file_count']}", "", "## Manifests"]
    lines.extend([f"- {item}" for item in payload["manifests"]] or ["- None detected"])
    lines.extend(["", "## Workflows"])
    lines.extend([f"- {item}" for item in payload["workflows"]] or ["- None detected"])
    lines.extend(["", "## Top extensions"])
    lines.extend([f"- {ext}: {count}" for ext, count in payload["top_extensions"]])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a compact repository brief.")
    parser.add_argument("path", nargs="?", default=".", help="Repository root or subdirectory.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    payload = inventory(Path(args.path))
    if args.markdown:
        sys.stdout.write(to_markdown(payload))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
