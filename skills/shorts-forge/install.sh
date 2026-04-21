#!/usr/bin/env bash
set -euo pipefail

ASSET_DIR="${ASSET_DIR:-$HOME/.shorts-forge/assets}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/shorts}"

echo "🎬 shorts-forge — setup"

# Check required binaries
MISSING=()
for bin in ffmpeg python3; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  echo "   Install ffmpeg: sudo apt install ffmpeg  (Debian/Ubuntu)"
  echo "                   sudo pacman -S ffmpeg     (Arch)"
  exit 1
fi

# Check for nvenc support (informational only)
if ffmpeg -encoders 2>/dev/null | grep -q h264_nvenc; then
  echo "✅ h264_nvenc (GPU) encoder detected"
else
  echo "ℹ️  h264_nvenc not available — CPU libx264 will be used (slower but equivalent output)"
fi

mkdir -p "$ASSET_DIR" "$OUTPUT_DIR"

echo ""
echo "✅ shorts-forge is ready."
echo "   Asset dir  : $ASSET_DIR"
echo "   Output dir : $OUTPUT_DIR"
echo ""
echo "Next step: add royalty-free .mp4 background clips to:"
echo "  $ASSET_DIR"
echo ""
echo "Recommended sources: pexels.com/videos  pixabay.com/videos"
echo ""
echo "Required env vars:"
echo "  export OUTPUT_DIR='$OUTPUT_DIR'"
echo "  export ASSET_DIR='$ASSET_DIR'     # optional, uses default if unset"
echo "  export CUDA_VISIBLE_DEVICES=0     # optional, for GPU encoding"

