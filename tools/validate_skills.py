#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:  # pragma: no cover - dependency handled in CI
    raise SystemExit(
        "PyYAML is required. Install it with: pip install pyyaml"
    ) from exc


VARIANTS = [
    "openclaw",
    "zeroclaw",
    "picoclaw",
    "nullclaw",
    "nanobot",
    "ironclaw",
]
VALID_COMPAT = {"full", "partial", "unsupported"}
VALID_TIERS = {"L1", "L2", "L3"}
FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n?", re.DOTALL)


def discover_skill_files(paths: list[str]) -> list[Path]:
    if not paths:
        paths = ["skills"]

    files: list[Path] = []
    for raw_path in paths:
        path = Path(raw_path)
        if path.is_dir():
            files.extend(sorted(path.glob("*/SKILL.md")))
        elif path.name == "SKILL.md":
            files.append(path)

    deduped = sorted({file.resolve() for file in files})
    return [Path(item) for item in deduped]


def load_frontmatter(skill_path: Path) -> dict:
    text = skill_path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)
    if not match:
        raise ValueError("missing YAML frontmatter")

    payload = yaml.safe_load(match.group(1)) or {}
    if not isinstance(payload, dict):
        raise ValueError("frontmatter must decode to a mapping")
    return payload


def validate_skill(skill_path: Path) -> tuple[list[str], dict | None]:
    errors: list[str] = []
    try:
        data = load_frontmatter(skill_path)
    except Exception as exc:  # pylint: disable=broad-except
        return [f"{skill_path}: {exc}"], None

    for key in ("name", "description", "version", "metadata"):
        if key not in data:
            errors.append(f"{skill_path}: missing top-level field '{key}'")

    metadata = data.get("metadata", {})
    openclaw = metadata.get("openclaw", {}) if isinstance(metadata, dict) else {}
    if not openclaw:
        errors.append(f"{skill_path}: missing metadata.openclaw mapping")
        return errors, data

    requires = openclaw.get("requires", {})
    compat = openclaw.get("compat", {})
    tags = openclaw.get("tags", [])
    tier = openclaw.get("security_tier")

    if not isinstance(requires, dict):
        errors.append(f"{skill_path}: metadata.openclaw.requires must be a mapping")
    else:
        if "bins" not in requires:
            errors.append(f"{skill_path}: missing metadata.openclaw.requires.bins")
        if "env" not in requires:
            errors.append(f"{skill_path}: missing metadata.openclaw.requires.env")

    if not isinstance(compat, dict):
        errors.append(f"{skill_path}: metadata.openclaw.compat must be a mapping")
    else:
        missing = [variant for variant in VARIANTS if variant not in compat]
        if missing:
            errors.append(
                f"{skill_path}: missing compatibility keys: {', '.join(missing)}"
            )
        for variant, status in compat.items():
            if status not in VALID_COMPAT:
                errors.append(
                    f"{skill_path}: invalid compatibility status '{status}' for {variant}"
                )

    if tier not in VALID_TIERS:
        errors.append(f"{skill_path}: security_tier must be one of {sorted(VALID_TIERS)}")

    if not isinstance(tags, list) or not tags:
        errors.append(f"{skill_path}: metadata.openclaw.tags must be a non-empty list")

    return errors, data


def markdown_table(results: list[tuple[Path, dict]]) -> str:
    lines = [
        "| Skill | Tier | OpenClaw | ZeroClaw | PicoClaw | NullClaw | NanoBot | IronClaw |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for path, data in results:
        openclaw = data["metadata"]["openclaw"]
        compat = openclaw["compat"]
        lines.append(
            "| {skill} | {tier} | {openclaw_v} | {zeroclaw} | {picoclaw} | {nullclaw} | {nanobot} | {ironclaw} |".format(
                skill=path.parent.name,
                tier=openclaw["security_tier"],
                openclaw_v=compat["openclaw"],
                zeroclaw=compat["zeroclaw"],
                picoclaw=compat["picoclaw"],
                nullclaw=compat["nullclaw"],
                nanobot=compat["nanobot"],
                ironclaw=compat["ironclaw"],
            )
        )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate ClawForge SKILL.md files.")
    parser.add_argument(
        "paths",
        nargs="*",
        help="Directories or SKILL.md files to validate (defaults to skills/).",
    )
    parser.add_argument(
        "--markdown-table",
        action="store_true",
        help="Print a compatibility table after successful validation.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the parsed metadata as JSON after successful validation.",
    )
    args = parser.parse_args()

    skill_files = discover_skill_files(args.paths)
    if not skill_files:
        print("No SKILL.md files found.", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    parsed: list[tuple[Path, dict]] = []

    for skill_file in skill_files:
        errors, data = validate_skill(skill_file)
        all_errors.extend(errors)
        if data is not None and not errors:
            parsed.append((skill_file, data))

    if all_errors:
        for error in all_errors:
            print(error, file=sys.stderr)
        return 1

    if args.markdown_table:
        print(markdown_table(parsed))
    elif args.json:
        payload = {path.parent.name: data for path, data in parsed}
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(f"Validated {len(parsed)} skill definition(s).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
