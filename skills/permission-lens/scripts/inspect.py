#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if sys.path and Path(sys.path[0]).resolve() == SCRIPT_DIR:
    sys.path.pop(0)

import argparse
import ast
import json
import os
import re

BIN_RISK_MAP = {
    "curl": "outbound HTTP",
    "wget": "outbound HTTP",
    "sudo": "privilege escalation",
    "rm": "destructive file ops",
    "docker": "container management",
    "aws": "AWS API access",
    "terraform": "infrastructure changes",
    "pacman": "package management",
    "git": "repository access",
    "python3": "script execution",
    "gitleaks": "filesystem scan",
    "trufflehog": "filesystem scan",
    "checkov": "static analysis",
    "tfsec": "static analysis",
    "jq": "JSON processing",
    "awk": "text processing",
    "sed": "text processing",
    "nc": "raw network (HIGH RISK)",
    "ncat": "raw network (HIGH RISK)",
    "socat": "raw network (HIGH RISK)",
}
SENSITIVE_ENV_TOKENS = ("TOKEN", "SECRET", "KEY", "PASSWORD", "CREDENTIAL")
RISK_LABELS = {"L1": "green", "L2": "amber", "L3": "red"}
COLOR_CODES = {"green": "\033[32m", "amber": "\033[33m", "red": "\033[31m", "unknown": "\033[0m"}
RESET = "\033[0m"
VARIANT_ORDER = ["openclaw", "zeroclaw", "picoclaw", "nullclaw", "nanobot", "ironclaw"]


def extract_frontmatter(text: str) -> str:
    match = re.match(r"^---\n(.*?)\n---\s*", text, re.DOTALL)
    if not match:
        raise ValueError("Could not locate YAML frontmatter between --- markers.")
    return match.group(1)


def parse_scalar(raw: str):
    raw = raw.strip()
    if raw in {"null", "~", "None"}:
        return None
    if raw.lower() == "true":
        return True
    if raw.lower() == "false":
        return False
    if raw.startswith("[") and raw.endswith("]"):
        normalized = re.sub(r"\bnull\b", "None", raw)
        normalized = re.sub(r"\btrue\b", "True", normalized, flags=re.IGNORECASE)
        normalized = re.sub(r"\bfalse\b", "False", normalized, flags=re.IGNORECASE)
        try:
            value = ast.literal_eval(normalized)
        except Exception:
            value = [item.strip().strip("\"'") for item in raw[1:-1].split(",") if item.strip()]
        return list(value)
    if (raw.startswith('"') and raw.endswith('"')) or (raw.startswith("'") and raw.endswith("'")):
        return ast.literal_eval(raw)
    return raw


def fallback_parse(frontmatter: str) -> dict:
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for raw_line in frontmatter.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()
        if ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        while stack and indent <= stack[-1][0]:
            stack.pop()
        current = stack[-1][1]
        value = value.strip()
        if value == "":
            node: dict = {}
            current[key] = node
            stack.append((indent, node))
        else:
            current[key] = parse_scalar(value)
    return root


def parse_frontmatter(frontmatter: str) -> dict:
    try:
        import yaml  # type: ignore
    except Exception:
        yaml = None
    if yaml is not None:
        try:
            parsed = yaml.safe_load(frontmatter)
            if isinstance(parsed, dict):
                return parsed
        except Exception:
            pass
    parsed = fallback_parse(frontmatter)
    if not isinstance(parsed, dict):
        raise ValueError("Unable to parse YAML frontmatter.")
    return parsed


def env_risk(env_name: str) -> str:
    upper = env_name.upper()
    if any(token in upper for token in SENSITIVE_ENV_TOKENS):
        return "credential access"
    return "configuration input"


def build_manifest(data: dict, path: Path) -> dict:
    metadata = data.get("metadata", {}).get("openclaw", {})
    requires = metadata.get("requires", {})
    bins = list(requires.get("bins") or [])
    env_vars = list(requires.get("env") or [])
    compat = dict(metadata.get("compat") or {})
    tags = list(metadata.get("tags") or [])
    security_tier = metadata.get("security_tier", "unknown")
    risk_label = RISK_LABELS.get(security_tier, "unknown")
    bins_risk = [{"bin": name, "risk": BIN_RISK_MAP.get(name, "general execution")} for name in bins]
    env_risk_items = [{"env": name, "risk": env_risk(name)} for name in env_vars]

    network_bins = [
        item["bin"]
        for item in bins_risk
        if "HTTP" in item["risk"] or "network" in item["risk"] or "API access" in item["risk"]
    ]
    destructive_bins = [
        item["bin"]
        for item in bins_risk
        if "destructive" in item["risk"] or item["bin"] in {"terraform", "docker", "sudo", "pacman"}
    ]
    read_summary = "Reads local SKILL metadata and related repository files to explain requested capabilities."
    write_summary = {
        "L1": "No direct write capability is implied by the declared security tier.",
        "L2": "May change local or managed state after explicit approval.",
        "L3": "May influence credentialed infrastructure or production-adjacent systems; treat changes as high risk.",
    }.get(security_tier, "Write risk could not be inferred from the declared security tier.")
    callout_summary = "Calls out to: " + (", ".join(network_bins) if network_bins else "none declared")
    credential_summary = "Requires credentials: " + (", ".join(env_vars) if env_vars else "none declared")
    plain_english_summary = " ".join(
        part
        for part in [
            f"{data.get('name', path.parent.name)} is a {security_tier} skill with a {risk_label} risk label.",
            f"Required bins: {', '.join(bins) if bins else 'none declared'}.",
            f"Potentially state-changing bins: {', '.join(destructive_bins) if destructive_bins else 'none declared'}.",
            credential_summary + ".",
            callout_summary + ".",
        ]
        if part
    )

    return {
        "skill": data.get("name", path.parent.name),
        "description": data.get("description", ""),
        "security_tier": security_tier,
        "risk_label": risk_label,
        "bins_risk": bins_risk,
        "env_risk": env_risk_items,
        "compat": compat,
        "tags": tags,
        "plain_english_summary": plain_english_summary,
        "capabilities": {
            "read": read_summary,
            "write": write_summary,
            "call_out": callout_summary,
            "credentials": credential_summary,
        },
    }


def colorize(label: str, color_name: str) -> str:
    if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
        return label
    return f"{COLOR_CODES.get(color_name, RESET)}{label}{RESET}"


def render_text(manifest: dict) -> str:
    risk_line = colorize(manifest["risk_label"], manifest["risk_label"])
    lines = [
        f"permission manifest: {manifest['skill']}",
        f"description: {manifest.get('description', '')}",
        f"security tier: {manifest['security_tier']} ({risk_line})",
        "",
        "plain-english summary:",
        f"- {manifest['plain_english_summary']}",
        "",
        "required bins:",
    ]
    if manifest["bins_risk"]:
        for item in manifest["bins_risk"]:
            lines.append(f"- {item['bin']}: {item['risk']}")
    else:
        lines.append("- none declared")

    lines.extend(["", "required environment variables:"])
    if manifest["env_risk"]:
        for item in manifest["env_risk"]:
            lines.append(f"- {item['env']}: {item['risk']}")
    else:
        lines.append("- none declared")

    lines.extend(
        [
            "",
            "capabilities:",
            f"- read: {manifest['capabilities']['read']}",
            f"- write: {manifest['capabilities']['write']}",
            f"- call out: {manifest['capabilities']['call_out']}",
            f"- credentials: {manifest['capabilities']['credentials']}",
            "",
            "compatibility:",
            "variant | status",
            "--- | ---",
        ]
    )
    for variant in VARIANT_ORDER:
        if variant in manifest["compat"]:
            lines.append(f"{variant} | {manifest['compat'][variant]}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect a SKILL.md file and emit a permission manifest.")
    parser.add_argument("skill_md_path", help="Path to the target SKILL.md file")
    parser.add_argument("--format", choices=("json", "text"), default="text")
    args = parser.parse_args()

    path = Path(args.skill_md_path)
    if not path.exists() or not path.is_file() or path.name != "SKILL.md":
        raise SystemExit("TARGET_PATH must exist and point to a valid SKILL.md file.")

    text = path.read_text(encoding="utf-8")
    frontmatter = extract_frontmatter(text)
    manifest = build_manifest(parse_frontmatter(frontmatter), path)

    if args.format == "json":
        print(json.dumps(manifest, indent=2))
    else:
        print(render_text(manifest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
