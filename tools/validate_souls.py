#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:  # pragma: no cover
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
VALID_DOMAINS = {
    "devops",
    "security",
    "research",
    "productivity",
    "health",
    "creative",
    "finance",
}
VALID_TONES = {"terse", "balanced", "verbose"}
VALID_OUTPUTS = {"structured", "prose", "raw"}
VALID_COMPAT = {"full", "partial", "unsupported"}
VALID_TIERS = {"L1", "L2", "L3"}


def discover_soul_files(paths: list[str]) -> list[Path]:
    if not paths:
        paths = ["souls"]

    files: list[Path] = []
    for raw_path in paths:
        path = Path(raw_path)
        if path.is_dir():
            files.extend(sorted(path.glob("*/soul.yaml")))
        elif path.name == "soul.yaml":
            files.append(path)

    deduped = sorted({file.resolve() for file in files})
    return [Path(item) for item in deduped]


def validate_soul(soul_yaml_path: Path) -> tuple[list[str], dict | None]:
    errors: list[str] = []
    try:
        data = yaml.safe_load(soul_yaml_path.read_text(encoding="utf-8")) or {}
    except Exception as exc:  # pylint: disable=broad-except
        return [f"{soul_yaml_path}: {exc}"], None

    if not isinstance(data, dict):
        return [f"{soul_yaml_path}: soul.yaml must decode to a mapping"], None

    soul_dir = soul_yaml_path.parent
    dir_name = soul_dir.name

    # Required string fields
    for key in ("name", "display_name", "version", "author"):
        if key not in data:
            errors.append(f"{soul_yaml_path}: missing field '{key}'")
        elif not isinstance(data[key], str) or not data[key].strip():
            errors.append(f"{soul_yaml_path}: field '{key}' must be a non-empty string")

    # name must match directory
    if data.get("name") and data["name"] != dir_name:
        errors.append(
            f"{soul_yaml_path}: 'name' ({data['name']!r}) must match directory name ({dir_name!r})"
        )

    # domain
    domain = data.get("domain")
    if not domain:
        errors.append(f"{soul_yaml_path}: missing field 'domain'")
    elif domain not in VALID_DOMAINS:
        errors.append(
            f"{soul_yaml_path}: 'domain' must be one of {sorted(VALID_DOMAINS)}, got {domain!r}"
        )

    # tone
    tone = data.get("tone")
    if not tone:
        errors.append(f"{soul_yaml_path}: missing field 'tone'")
    elif tone not in VALID_TONES:
        errors.append(
            f"{soul_yaml_path}: 'tone' must be one of {sorted(VALID_TONES)}, got {tone!r}"
        )

    # preferred_output
    preferred_output = data.get("preferred_output")
    if not preferred_output:
        errors.append(f"{soul_yaml_path}: missing field 'preferred_output'")
    elif preferred_output not in VALID_OUTPUTS:
        errors.append(
            f"{soul_yaml_path}: 'preferred_output' must be one of {sorted(VALID_OUTPUTS)}, got {preferred_output!r}"
        )

    # activate_skills
    activate_skills = data.get("activate_skills")
    if not activate_skills:
        errors.append(f"{soul_yaml_path}: missing or empty field 'activate_skills'")
    elif not isinstance(activate_skills, list) or len(activate_skills) == 0:
        errors.append(f"{soul_yaml_path}: 'activate_skills' must be a non-empty list")

    # tags
    tags = data.get("tags")
    if not tags:
        errors.append(f"{soul_yaml_path}: missing or empty field 'tags'")
    elif not isinstance(tags, list) or len(tags) == 0:
        errors.append(f"{soul_yaml_path}: 'tags' must be a non-empty list")

    # compat
    compat = data.get("compat")
    if not compat:
        errors.append(f"{soul_yaml_path}: missing field 'compat'")
    elif not isinstance(compat, dict):
        errors.append(f"{soul_yaml_path}: 'compat' must be a mapping")
    else:
        missing = [v for v in VARIANTS if v not in compat]
        if missing:
            errors.append(
                f"{soul_yaml_path}: missing compat keys: {', '.join(missing)}"
            )
        for variant, status in compat.items():
            if status not in VALID_COMPAT:
                errors.append(
                    f"{soul_yaml_path}: invalid compat status {status!r} for {variant}"
                )

    # security_tier_cap (optional but must be valid if present)
    tier_cap = data.get("security_tier_cap")
    if tier_cap is not None and tier_cap not in VALID_TIERS:
        errors.append(
            f"{soul_yaml_path}: 'security_tier_cap' must be one of {sorted(VALID_TIERS)}, got {tier_cap!r}"
        )

    # SOUL.md must exist alongside soul.yaml
    soul_md = soul_dir / "SOUL.md"
    if not soul_md.exists():
        errors.append(f"{soul_yaml_path}: missing required SOUL.md in {soul_dir}")

    return errors, data


def markdown_table(results: list[tuple[Path, dict]]) -> str:
    lines = [
        "| Soul | Domain | Tone | OpenClaw | ZeroClaw | PicoClaw | NullClaw | NanoBot | IronClaw |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for path, data in results:
        compat = data.get("compat", {})
        lines.append(
            "| {soul} | {domain} | {tone} | {openclaw} | {zeroclaw} | {picoclaw} | {nullclaw} | {nanobot} | {ironclaw} |".format(
                soul=path.parent.name,
                domain=data.get("domain", ""),
                tone=data.get("tone", ""),
                openclaw=compat.get("openclaw", ""),
                zeroclaw=compat.get("zeroclaw", ""),
                picoclaw=compat.get("picoclaw", ""),
                nullclaw=compat.get("nullclaw", ""),
                nanobot=compat.get("nanobot", ""),
                ironclaw=compat.get("ironclaw", ""),
            )
        )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate ClawForge soul.yaml files.")
    parser.add_argument(
        "paths",
        nargs="*",
        help="Directories or soul.yaml files to validate (defaults to souls/).",
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

    soul_files = discover_soul_files(args.paths)
    if not soul_files:
        print("No soul.yaml files found.", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    parsed: list[tuple[Path, dict]] = []

    for soul_file in soul_files:
        errors, data = validate_soul(soul_file)
        all_errors.extend(errors)
        if data is not None and not errors:
            parsed.append((soul_file, data))

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
        print(f"Validated {len(parsed)} soul definition(s).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
