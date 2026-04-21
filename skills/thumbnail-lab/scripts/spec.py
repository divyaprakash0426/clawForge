#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

STOPWORDS = {"the", "a", "an", "and", "or", "to", "of", "for", "with", "in", "on", "your", "this", "that", "is", "are"}


def read_text(source: str) -> str:
    if source == "-":
        return sys.stdin.read()
    return Path(source).read_text(encoding="utf-8")


def sentences(text: str) -> list[str]:
    parts = re.split(r"[\n.!?]+", text)
    return [part.strip() for part in parts if part.strip()]


def compress(line: str, limit: int) -> str:
    words = [word for word in re.findall(r"[A-Za-z0-9']+", line) if word.lower() not in STOPWORDS]
    if not words:
        return line.strip()[:limit]
    phrase = " ".join(words[:limit])
    return phrase.title()


def build_spec(text: str) -> dict:
    beats = sentences(text)[:6]
    hooks = [compress(beat, 6) for beat in beats[:3]] or ["Strong Before And After"]
    overlays = [compress(beat, 4) for beat in beats[:4]] or ["Clear Value Fast"]
    shots = []
    for index, beat in enumerate(beats, start=1):
        cue = "reaction close-up"
        lowered = beat.lower()
        if "before" in lowered or "after" in lowered:
            cue = "before/after split frame"
        elif any(token in lowered for token in ("show", "demo", "build", "make")):
            cue = "hands-on demo frame"
        elif any(token in lowered for token in ("result", "proof", "outcome")):
            cue = "result reveal frame"
        shots.append({"beat": index, "source": beat, "prompt": cue})
    return {"hooks": hooks, "overlays": overlays, "shots": shots}


def to_markdown(payload: dict) -> str:
    lines = ["# thumbnail-lab brief", "", "## Hook options"]
    lines.extend([f"- {item}" for item in payload["hooks"]])
    lines.extend(["", "## Overlay copy"])
    lines.extend([f"- {item}" for item in payload["overlays"]])
    lines.extend(["", "## Shot prompts"])
    for shot in payload["shots"]:
        lines.append(f"- Beat {shot['beat']}: {shot['prompt']} — {shot['source']}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate thumbnail planning notes from script text.")
    parser.add_argument("source", help="Text file path or - for stdin.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown instead of JSON.")
    args = parser.parse_args()

    payload = build_spec(read_text(args.source))
    if args.markdown:
        sys.stdout.write(to_markdown(payload))
    else:
        json.dump(payload, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
