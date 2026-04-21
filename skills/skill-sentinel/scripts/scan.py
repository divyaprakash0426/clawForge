#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import urllib.request
from pathlib import Path


PATTERNS = [
    (
        "prompt-injection",
        re.compile(
            r"ignore (all|previous) instructions|reveal (your|the) (system|hidden) prompt",
            re.IGNORECASE,
        ),
        4,
        "Prompt-injection phrasing detected.",
    ),
    (
        "shell-pipe",
        re.compile(r"\b(?:curl|wget)\b[^\n|]*\|\s*(?:sh|bash)\b", re.IGNORECASE),
        4,
        "Remote fetch piped directly into a shell.",
    ),
    (
        "raw-ip-fetch",
        re.compile(
            r"\b(?:curl|wget)\b[^\n]*https?://(?:\d{1,3}\.){3}\d{1,3}\b",
            re.IGNORECASE,
        ),
        3,
        "Fetch to a raw IP address.",
    ),
    (
        "encoded-payload",
        re.compile(r"\bbase64\b[^\n]*(?:-d|--decode)|python\s+-c\s+['\"].*base64", re.IGNORECASE),
        3,
        "Encoded payload or decode-and-run pattern detected.",
    ),
    (
        "secret-read",
        re.compile(
            r"\$(?:\{)?[A-Z0-9_]*(?:TOKEN|SECRET|PASSWORD|API_KEY|ACCESS_KEY)[A-Z0-9_]*\}?",
            re.IGNORECASE,
        ),
        3,
        "Secret-oriented environment variable read detected.",
    ),
    (
        "suspicious-bin",
        re.compile(r"\b(?:nc|ncat|socat|sshpass)\b", re.IGNORECASE),
        2,
        "Potentially risky networking or credential helper binary referenced.",
    ),
]


def load_target(target: str) -> str:
    if target.startswith(("http://", "https://")):
        with urllib.request.urlopen(target, timeout=15) as response:
            return response.read().decode("utf-8")
    path = Path(target)
    if path.is_dir():
        path = path / "SKILL.md"
    return path.read_text(encoding="utf-8")


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def scan_target(target: str) -> dict:
    text = load_target(target)
    findings = []
    risk_score = 0

    for code, pattern, score, message in PATTERNS:
        for match in pattern.finditer(text):
            risk_score += score
            findings.append(
                {
                    "code": code,
                    "message": message,
                    "score": score,
                    "line": line_number(text, match.start()),
                    "snippet": match.group(0)[:160],
                }
            )

    blocked = risk_score > 7
    return {
        "target": target,
        "risk_score": risk_score,
        "blocked": blocked,
        "findings": findings,
    }


def render_text(result: dict) -> str:
    status = "BLOCK" if result["blocked"] else "OK"
    lines = [
        f"[{status}] {result['target']} risk_score={result['risk_score']} findings={len(result['findings'])}"
    ]
    for finding in result["findings"]:
        lines.append(
            f"  - line {finding['line']}: {finding['code']} (+{finding['score']}) {finding['message']} :: {finding['snippet']}"
        )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan SKILL.md content for risky patterns.")
    parser.add_argument("targets", nargs="+", help="Local skill directories, SKILL.md paths, or remote URLs.")
    parser.add_argument(
        "--format",
        choices=("json", "text"),
        default="json",
        help="Output format.",
    )
    args = parser.parse_args()

    results = [scan_target(target) for target in args.targets]

    if args.format == "json":
        if len(results) == 1:
            print(json.dumps(results[0], indent=2))
        else:
            print(json.dumps(results, indent=2))
    else:
        for result in results:
            print(render_text(result))

    return 1 if any(result["blocked"] for result in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
