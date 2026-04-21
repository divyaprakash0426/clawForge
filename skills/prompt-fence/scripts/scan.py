#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

IGNORE_DIRS = {".git", "node_modules", ".venv", "venv", "dist", "build", "target"}
TEXT_EXTS = {".md", ".txt", ".yaml", ".yml", ".json", ".prompt", ".cfg", ".ini", ".sh"}
RULES = [
    ("high", "boundary-bypass", re.compile(r"ignore (all|any|previous|prior) (instructions|rules)", re.IGNORECASE)),
    ("high", "secret-exfiltration", re.compile(r"(print|reveal|send|upload).*(api key|token|secret|password|ssh)", re.IGNORECASE)),
    ("high", "unsafe-shell", re.compile(r"curl\s+[^|]+\|\s*(bash|sh)|base64\s+-d\s*\|\s*(bash|sh)", re.IGNORECASE)),
    ("medium", "policy-disable", re.compile(r"disable (safety|guardrails|protections)|jailbreak", re.IGNORECASE)),
    ("medium", "env-dump", re.compile(r"env\b|printenv|\.ssh|aws_credentials|id_rsa", re.IGNORECASE)),
]


def discover(paths: list[str]) -> list[Path]:
    found: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            for current, dirs, files in os.walk(path):
                dirs[:] = [item for item in dirs if item not in IGNORE_DIRS]
                for name in files:
                    candidate = Path(current) / name
                    if candidate.suffix.lower() in TEXT_EXTS or candidate.name in {"SKILL.md", "README.md", "COMPAT.md"}:
                        found.append(candidate)
        elif path.is_file():
            found.append(path)
    unique = []
    for item in sorted({item.resolve() for item in found}):
        if item.stat().st_size <= 300_000:
            unique.append(item)
    return unique


def scan(path: Path) -> list[dict]:
    findings = []
    for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        for severity, rule, pattern in RULES:
            if pattern.search(line):
                findings.append({
                    "file": str(path),
                    "line": number,
                    "severity": severity,
                    "rule": rule,
                    "text": line.strip()[:220],
                })
    return findings


def to_markdown(payload: dict) -> str:
    lines = ["# prompt-fence report", "", f"- Files scanned: {payload['file_count']}", f"- Findings: {payload['finding_count']}", ""]
    if not payload["findings"]:
        lines.append("No findings matched the built-in prompt-fence rules.")
    else:
        for finding in payload["findings"]:
            lines.append(f"- [{finding['severity']}] {finding['file']}:L{finding['line']} {finding['rule']} — {finding['text']}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan prompt files for risky phrases.")
    parser.add_argument("paths", nargs="+", help="Files or directories to scan.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    files = discover(args.paths)
    if not files:
        raise SystemExit("No matching text files found.")
    findings = []
    for path in files:
        findings.extend(scan(path))
    payload = {
        "file_count": len(files),
        "files": [str(path) for path in files],
        "finding_count": len(findings),
        "findings": findings,
    }
    if args.markdown:
        sys.stdout.write(to_markdown(payload))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
