#!/usr/bin/env bash
# blog-pipeline entrypoint
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "✍️  blog-pipeline"
echo ""

case "${1:-help}" in
  lint)    shift; bash "$SCRIPT_DIR/lint-draft.sh" "$@" ;;
  seo)     shift; bash "$SCRIPT_DIR/seo-check.sh" "$@" ;;
  publish) shift; bash "$SCRIPT_DIR/publish.sh" "$@" ;;
  *)
    echo "Usage: run.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  lint <post.md>                     Validate frontmatter and links"
    echo "  seo <post.md>                      SEO score and uniqueness check"
    echo "  publish <post.md> [--target pages|devto|both] [--dry-run]"
    ;;
esac
