#!/usr/bin/env bash
# Render a short-form video from script.json using ffmpeg
# Usage: render.sh <script.json> [voiceover.mp3] [--bg-clip <clip.mp4>]
set -euo pipefail

SCRIPT_JSON="${1:-}"
VOICEOVER=""
BG_CLIP=""
ASSET_DIR="${ASSET_DIR:-$HOME/.shorts-forge/assets}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/shorts}"

if [[ -z "$SCRIPT_JSON" || ! -f "$SCRIPT_JSON" ]]; then
  echo "Usage: render.sh <script.json> [voiceover.mp3] [--bg-clip <clip.mp4>]"
  echo "  script.json is produced by validate-script.sh"
  exit 1
fi

# Parse remaining args
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bg-clip) BG_CLIP="$2"; shift 2 ;;
    *.mp3|*.wav|*.aac) VOICEOVER="$1"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Verify ffmpeg
command -v ffmpeg &>/dev/null || { echo "❌ ffmpeg not found. Install it first."; exit 1; }

mkdir -p "$OUTPUT_DIR"

# Select background clip
if [[ -z "$BG_CLIP" ]]; then
  mapfile -t CLIPS < <(find "$ASSET_DIR" -name "*.mp4" 2>/dev/null)
  if [[ ${#CLIPS[@]} -eq 0 ]]; then
    echo "❌ No .mp4 clips found in $ASSET_DIR"
    echo "   Add royalty-free clips or use --bg-clip <path>"
    exit 1
  fi
  # Pick a random clip
  BG_CLIP="${CLIPS[$((RANDOM % ${#CLIPS[@]}))]}"
  echo "ℹ️  Selected background clip: $BG_CLIP"
fi

# Read scenes and build drawtext filter
SCENES_DATA=$(python3 - "$SCRIPT_JSON" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    scenes = json.load(f)

# Calculate cumulative start times
t = 0
filters = []
for s in scenes:
    dur   = s["duration_hint_s"]
    text  = s["text"].replace("'", "\\'").replace(":", "\\:")
    filters.append(f"drawtext=text='{text}':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=h-150:shadowcolor=black:shadowx=2:shadowy=2:enable='between(t,{t},{t+dur})'")
    t += dur

total = t
print(f"TOTAL_DURATION={total}")
print(f"DRAWTEXT=" + ",".join(filters))
PYEOF
)

eval "$SCENES_DATA"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/short_${TIMESTAMP}.mp4"

# Choose encoder
if ffmpeg -encoders 2>/dev/null | grep -q h264_nvenc; then
  ENCODER="-c:v h264_nvenc -preset p4 -b:v 4M"
  echo "ℹ️  Using GPU encoder: h264_nvenc"
else
  ENCODER="-c:v libx264 -preset fast -crf 23"
  echo "ℹ️  Using CPU encoder: libx264"
fi

echo "🎬 Rendering..."

# Build ffmpeg command
AUDIO_ARGS=()
if [[ -n "$VOICEOVER" && -f "$VOICEOVER" ]]; then
  AUDIO_ARGS=(-i "$VOICEOVER" -c:a aac -b:a 128k -shortest)
else
  AUDIO_ARGS=(-an)
fi

ffmpeg -y \
  -stream_loop -1 -i "$BG_CLIP" \
  "${AUDIO_ARGS[@]}" \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,${DRAWTEXT}" \
  -t "$TOTAL_DURATION" \
  -r 30 \
  $ENCODER \
  "$OUTPUT_FILE" 2>&1 | tail -5

echo ""
echo "✅ Render complete"
echo "   Output    : $OUTPUT_FILE"
echo "   Duration  : ${TOTAL_DURATION}s"
echo "   Resolution: 1080×1920 @ 30fps"
