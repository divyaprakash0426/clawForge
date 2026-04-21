#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

RULES = {
    "errors": re.compile(r"(?:^|\b)(error|fatal|::error::)(?:\b|:)", re.IGNORECASE),
    "warnings": re.compile(r"(?:^|\b)(warning|::warning::)(?:\b|:)", re.IGNORECASE),
    "failures": re.compile(r"(?:^|\b)(failed|failure|exception|panic)(?:\b|:)", re.IGNORECASE),
    "tracebacks": re.compile(r"traceback|stack trace|stacktrace", re.IGNORECASE),
}


def read_text(target: str) -> tuple[str, str]:
    if target == "-":
        return "stdin", sys.stdin.read()
    path = Path(target)
    return str(path), path.read_text(encoding="utf-8", errors="replace")


def summarize(label: str, text: str) -> dict:
    lines = text.splitlines()
    counts = {name: 0 for name in RULES}
    excerpts: list[dict] = []
    for number, line in enumerate(lines, start=1):
        matched = [name for name, pattern in RULES.items() if pattern.search(line)]
        if not matched:
            continue
        for name in matched:
            counts[name] += 1
        if len(excerpts) < 8:
            excerpts.append({
                "line": number,
                "tags": matched,
                "text": line.strip()[:220],
            })
    next_actions = []
    if counts["errors"] or counts["failures"]:
        next_actions.append("Inspect the first error excerpt before rerunning the job.")
    if counts["tracebacks"]:
        next_actions.append("Traceback markers exist; pull the surrounding stack frames if available.")
    if not next_actions:
        next_actions.append("No explicit failure markers found; verify whether the log is incomplete.")
    return {
        "source": label,
        "line_count": len(lines),
        "counts": counts,
        "excerpts": excerpts,
        "next_actions": next_actions,
    }


def to_markdown(payloads: list[dict]) -> str:
    lines = ["# ci-logbook summary", ""]
    for payload in payloads:
        lines.extend([
            f"## {payload['source']}",
            f"- Lines: {payload['line_count']}",
            f"- Errors: {payload['counts']['errors']}",
            f"- Warnings: {payload['counts']['warnings']}",
            f"- Failures: {payload['counts']['failures']}",
            f"- Tracebacks: {payload['counts']['tracebacks']}",
            "- Excerpts:",
        ])
        if payload["excerpts"]:
            for excerpt in payload["excerpts"]:
                tags = ", ".join(excerpt["tags"])
                lines.append(f"  - L{excerpt['line']} [{tags}] {excerpt['text']}")
        else:
            lines.append("  - No high-signal lines matched the built-in patterns.")
        lines.append("- Next actions:")
        for action in payload["next_actions"]:
            lines.append(f"  - {action}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize CI log files.")
    parser.add_argument("paths", nargs="+", help="Log files to scan, or - for stdin.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    payloads = []
    for target in args.paths:
        label, text = read_text(target)
        payloads.append(summarize(label, text))

    if args.markdown:
        sys.stdout.write(to_markdown(payloads))
    else:
        json.dump(payloads, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
