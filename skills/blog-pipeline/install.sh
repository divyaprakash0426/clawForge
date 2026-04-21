#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.blog-pipeline"

echo "✍️  blog-pipeline — setup"

# Check required binaries
MISSING=()
for bin in git gh pandoc curl jq; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required binaries: ${MISSING[*]}"
  echo "   pandoc: sudo apt install pandoc  (Debian/Ubuntu)"
  echo "   gh:     https://cli.github.com/manual/installation"
  exit 1
fi

mkdir -p "$CONFIG_DIR"

# Seed empty published bloom-filter placeholder
touch "$CONFIG_DIR/published.bloom"

# Check for GITHUB_TOKEN
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "⚠️  GITHUB_TOKEN is not set — required for GitHub Pages publishing."
  echo "   Set it in ~/.bashrc: export GITHUB_TOKEN='ghp_...'"
fi

# Check for optional DEVTO_API_KEY
if [[ -z "${DEVTO_API_KEY:-}" ]]; then
  echo "ℹ️  DEVTO_API_KEY is not set — dev.to publishing will be unavailable."
fi

echo ""
echo "✅ blog-pipeline is ready."
echo "   Config dir : $CONFIG_DIR"
echo ""
echo "Required env vars:"
echo "  export GITHUB_TOKEN='ghp_...'         # GitHub Pages push"
echo "  export SITE_URL='https://yoursite.com'"
echo ""
echo "Optional:"
echo "  export DEVTO_API_KEY='...'            # dev.to publishing"

