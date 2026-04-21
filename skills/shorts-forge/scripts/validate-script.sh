#!/usr/bin/env bash
# Validate a short-form video script: word count, scene segmentation, emit script.json
set -euo pipefail

SCRIPT_FILE="${1:-}"

if [[ -z "$SCRIPT_FILE" ]]; then
  echo "Usage: validate-script.sh <script.txt>"
  exit 1
fi

if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "❌ File not found: $SCRIPT_FILE"
  exit 1
fi

python3 - "$SCRIPT_FILE" << 'PYEOF'
import sys, json, re, os

script_file = sys.argv[1]
out_file    = os.path.splitext(script_file)[0] + ".json"

with open(script_file) as f:
    raw = f.read().strip()

# Split into scenes at blank lines
scenes_raw = [s.strip() for s in re.split(r'\n\s*\n', raw) if s.strip()]

total_words = sum(len(s.split()) for s in scenes_raw)

errors   = []
warnings = []

# Word count guidance
if total_words < 30:
    errors.append(f"Script is very short ({total_words} words). Minimum ~60 for a 30 s short.")
elif total_words > 200:
    errors.append(f"Script is too long ({total_words} words). Keep under 200 for short-form.")
elif total_words < 60:
    warnings.append(f"Script is on the short side ({total_words} words). Target: 60–90 words.")
elif total_words > 120:
    warnings.append(f"Script is longer than ideal ({total_words} words). Consider trimming to 60–90.")

# Per-scene checks
scenes = []
for i, text in enumerate(scenes_raw, 1):
    words = len(text.split())
    duration_hint = max(2, round(words / 2.5))  # rough TTS pacing: ~2.5 words/s
    scene = {"scene_id": i, "text": text, "duration_hint_s": duration_hint, "word_count": words}
    scenes.append(scene)
    if words > 25:
        warnings.append(f"Scene {i} has {words} words — consider splitting for readability.")

# Report
print(f"\n🎬 shorts-forge — script validation\n")
print(f"  File       : {script_file}")
print(f"  Scenes     : {len(scenes)}")
print(f"  Total words: {total_words}")
est_duration = sum(s["duration_hint_s"] for s in scenes)
print(f"  Est. length: ~{est_duration} s")

if errors:
    print()
    for e in errors:
        print(f"  ❌ {e}")
    print()
    print("Fix errors before rendering.")
    sys.exit(1)

if warnings:
    print()
    for w in warnings:
        print(f"  ⚠️  {w}")

with open(out_file, "w") as f:
    json.dump(scenes, f, indent=2)
    f.write("\n")

print(f"\n  ✅ script.json written to: {out_file}")
print()
print("TTS prompts (paste into your TTS tool):")
for s in scenes:
    print(f"  Scene {s['scene_id']}: {s['text']}")
PYEOF
