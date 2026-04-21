#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit("PyYAML is required. Install it with: python3 -m pip install pyyaml") from exc

POD_KINDS = {"Pod", "Deployment", "StatefulSet", "DaemonSet", "ReplicaSet", "ReplicationController", "Job", "CronJob"}


def iter_yaml_files(paths: list[str]) -> list[Path]:
    found: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            found.extend(sorted(path.rglob("*.yml")))
            found.extend(sorted(path.rglob("*.yaml")))
        elif path.suffix in {".yml", ".yaml"}:
            found.append(path)
    return sorted({item.resolve() for item in found})


def pod_spec(doc: dict) -> dict | None:
    kind = doc.get("kind")
    if kind not in POD_KINDS:
        return None
    spec = doc.get("spec", {})
    if kind in {"Deployment", "StatefulSet", "DaemonSet", "ReplicaSet", "ReplicationController", "Job"}:
        return spec.get("template", {}).get("spec", {})
    if kind == "CronJob":
        return spec.get("jobTemplate", {}).get("spec", {}).get("template", {}).get("spec", {})
    return spec


def inspect_doc(path: Path, doc: dict) -> list[dict]:
    findings: list[dict] = []
    spec = pod_spec(doc)
    if not spec:
        return findings
    kind = doc.get("kind", "Unknown")
    name = doc.get("metadata", {}).get("name", "unnamed")
    containers = list(spec.get("initContainers", [])) + list(spec.get("containers", []))
    for container in containers:
        cname = container.get("name", "unnamed")
        image = container.get("image", "")
        resources = container.get("resources", {})
        if not resources.get("requests") or not resources.get("limits"):
            findings.append({
                "severity": "warning",
                "file": str(path),
                "resource": f"{kind}/{name}",
                "container": cname,
                "rule": "missing-resources",
                "message": "Container is missing resource requests or limits.",
            })
        if image.endswith(":latest") or ":" not in image:
            findings.append({
                "severity": "warning",
                "file": str(path),
                "resource": f"{kind}/{name}",
                "container": cname,
                "rule": "weak-image-pin",
                "message": f"Image '{image or 'unknown'}' is unpinned or uses latest.",
            })
        if container.get("securityContext", {}).get("privileged") is True:
            findings.append({
                "severity": "critical",
                "file": str(path),
                "resource": f"{kind}/{name}",
                "container": cname,
                "rule": "privileged-container",
                "message": "Container runs with privileged=true.",
            })
    for flag in ("hostNetwork", "hostPID", "hostIPC"):
        if spec.get(flag) is True:
            findings.append({
                "severity": "critical",
                "file": str(path),
                "resource": f"{kind}/{name}",
                "rule": flag,
                "message": f"Pod spec enables {flag}.",
            })
    for volume in spec.get("volumes", []):
        if "hostPath" in volume:
            findings.append({
                "severity": "critical",
                "file": str(path),
                "resource": f"{kind}/{name}",
                "rule": "hostPath-volume",
                "message": f"Volume '{volume.get('name', 'unnamed')}' uses hostPath.",
            })
    return findings


def to_markdown(files: list[str], findings: list[dict]) -> str:
    lines = ["# kube-scout report", "", f"- Files scanned: {len(files)}", f"- Findings: {len(findings)}", ""]
    if not findings:
        lines.append("No findings matched the built-in safety checks.")
        return "\n".join(lines) + "\n"
    for finding in findings:
        container = f" ({finding['container']})" if "container" in finding else ""
        lines.append(f"- [{finding['severity']}] {finding['resource']}{container}: {finding['message']} [{finding['rule']}]")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit Kubernetes YAML for risky defaults.")
    parser.add_argument("paths", nargs="+", help="Manifest files or directories.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    yaml_files = iter_yaml_files(args.paths)
    if not yaml_files:
        raise SystemExit("No YAML manifests found.")

    findings: list[dict] = []
    resources_scanned = 0
    for path in yaml_files:
        for doc in yaml.safe_load_all(path.read_text(encoding="utf-8")):
            if not isinstance(doc, dict):
                continue
            if pod_spec(doc):
                resources_scanned += 1
            findings.extend(inspect_doc(path, doc))

    payload = {
        "files": [str(path) for path in yaml_files],
        "resources_scanned": resources_scanned,
        "finding_count": len(findings),
        "findings": findings,
    }
    if args.markdown:
        sys.stdout.write(to_markdown(payload["files"], findings))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
