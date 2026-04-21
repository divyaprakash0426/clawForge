#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None

IGNORE_DIRS = {".git", "node_modules", ".venv", "venv", "dist", "build", "target", "vendor"}
MANIFESTS = {"package.json", "requirements.txt", "pyproject.toml", "Cargo.toml", "go.mod"}
JS_LOCKS = {"package-lock.json", "pnpm-lock.yaml", "yarn.lock", "bun.lockb"}


def walk(root: Path) -> list[Path]:
    found = []
    for current, dirs, files in os.walk(root):
        dirs[:] = [item for item in dirs if item not in IGNORE_DIRS]
        for name in files:
            if name in MANIFESTS:
                found.append(Path(current) / name)
    return sorted(found)


def package_json(path: Path) -> list[dict]:
    import json as _json
    data = _json.loads(path.read_text(encoding="utf-8"))
    findings = []
    if not any((path.parent / lock).exists() for lock in JS_LOCKS):
        findings.append({"path": str(path), "rule": "missing-lockfile", "severity": "warning", "message": "No JS lockfile found next to package.json."})
    for section in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        for name, version in (data.get(section) or {}).items():
            if not isinstance(version, str):
                continue
            if version in {"*", "latest"} or any(token in version for token in ("git+", "github:", "git://", "file:", "link:")):
                findings.append({"path": str(path), "rule": "risky-source", "severity": "warning", "message": f"{section}:{name} uses '{version}'."})
    return findings


def requirements_txt(path: Path) -> list[dict]:
    findings = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith(("-r", "--")):
            continue
        if " @ " in line:
            findings.append({"path": str(path), "rule": "direct-url", "severity": "warning", "message": f"Line {number} uses a direct URL reference."})
        elif "==" not in line:
            findings.append({"path": str(path), "rule": "loose-pin", "severity": "warning", "message": f"Line {number} is not exactly pinned: {line}"})
    return findings


def pyproject(path: Path) -> list[dict]:
    findings = []
    if tomllib is None:
        return [{"path": str(path), "rule": "tomllib-missing", "severity": "warning", "message": "Python runtime lacks tomllib; pyproject parsing skipped."}]
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    deps = list((data.get("project", {}) or {}).get("dependencies", []) or [])
    optional = (data.get("project", {}) or {}).get("optional-dependencies", {}) or {}
    for group in optional.values():
        deps.extend(group or [])
    for dep in deps:
        if any(token in dep for token in (">=", "*", "git+", " @ ")):
            findings.append({"path": str(path), "rule": "loose-pin", "severity": "warning", "message": f"Dependency uses a broad or direct reference: {dep}"})
    return findings


def cargo_toml(path: Path) -> list[dict]:
    findings = []
    if tomllib is None:
        return [{"path": str(path), "rule": "tomllib-missing", "severity": "warning", "message": "Python runtime lacks tomllib; Cargo.toml parsing skipped."}]
    if not (path.parent / "Cargo.lock").exists():
        findings.append({"path": str(path), "rule": "missing-lockfile", "severity": "warning", "message": "Cargo.lock is missing next to Cargo.toml."})
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    for section_name in ("dependencies", "dev-dependencies", "build-dependencies"):
        for name, value in ((data.get(section_name) or {}).items()):
            if isinstance(value, str) and value == "*":
                findings.append({"path": str(path), "rule": "wildcard-version", "severity": "warning", "message": f"{section_name}:{name} uses '*'"})
            if isinstance(value, dict):
                if value.get("git") or value.get("path"):
                    findings.append({"path": str(path), "rule": "risky-source", "severity": "warning", "message": f"{section_name}:{name} uses git/path source."})
                if value.get("version") == "*":
                    findings.append({"path": str(path), "rule": "wildcard-version", "severity": "warning", "message": f"{section_name}:{name} uses wildcard version."})
    return findings


def go_mod(path: Path) -> list[dict]:
    findings = []
    if not (path.parent / "go.sum").exists():
        findings.append({"path": str(path), "rule": "missing-lockfile", "severity": "warning", "message": "go.sum is missing next to go.mod."})
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if line.startswith("replace "):
            findings.append({"path": str(path), "rule": "replace-directive", "severity": "warning", "message": f"Line {number} uses replace: {line}"})
        if re.search(r"=>\s+\.{1,2}/|=>\s+/", line):
            findings.append({"path": str(path), "rule": "local-path", "severity": "warning", "message": f"Line {number} points to a local path."})
    return findings


HANDLERS = {
    "package.json": package_json,
    "requirements.txt": requirements_txt,
    "pyproject.toml": pyproject,
    "Cargo.toml": cargo_toml,
    "go.mod": go_mod,
}


def to_markdown(payload: dict) -> str:
    lines = ["# dep-hygiene report", "", f"- Manifests scanned: {payload['manifest_count']}", f"- Findings: {payload['finding_count']}", ""]
    for finding in payload["findings"]:
        lines.append(f"- [{finding['severity']}] {finding['path']}: {finding['message']} [{finding['rule']}]")
    if not payload["findings"]:
        lines.append("No dependency hygiene issues matched the built-in rules.")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan dependency manifests for hygiene risks.")
    parser.add_argument("path", nargs="?", default=".", help="Repository root or subdirectory.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    root = Path(args.path)
    manifests = walk(root)
    findings = []
    for manifest in manifests:
        findings.extend(HANDLERS[manifest.name](manifest))
    payload = {
        "root": str(root.resolve()),
        "manifest_count": len(manifests),
        "manifests": [str(path) for path in manifests],
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
