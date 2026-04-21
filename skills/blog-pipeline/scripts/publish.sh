#!/usr/bin/env bash
# Publish a Markdown post to GitHub Pages and/or dev.to
set -euo pipefail

POST=""
TARGET="pages"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *.md)      POST="$1"; shift ;;
    *)         echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$POST" || ! -f "$POST" ]]; then
  echo "Usage: publish.sh <post.md> [--target pages|devto|both] [--dry-run]"
  exit 1
fi

SITE_URL="${SITE_URL:-https://example.com}"
POSTS_DIR="${POSTS_DIR:-_posts}"
CONFIG_DIR="$HOME/.blog-pipeline"
BLOOM_FILE="$CONFIG_DIR/published.bloom"
mkdir -p "$CONFIG_DIR"

SLUG=$(basename "$POST" .md)

echo "✍️  blog-pipeline — publish"
echo "  Post   : $POST"
echo "  Target : $TARGET"
[[ "$DRY_RUN" == "true" ]] && echo "  Mode   : DRY RUN (no changes will be made)"
echo ""

publish_pages() {
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "❌ GITHUB_TOKEN is not set — cannot push to GitHub Pages."
    return 1
  fi

  DEST="$POSTS_DIR/$SLUG.md"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] Would copy $POST → $DEST"
    echo "  [dry-run] Would: git add $DEST && git commit -m 'Add: $SLUG' && git push"
    return 0
  fi

  # Check for uncommitted changes in posts dir
  if git -C "$(dirname "$POSTS_DIR")" status --porcelain "$POSTS_DIR" 2>/dev/null | grep -q .; then
    echo "❌ Uncommitted changes in $POSTS_DIR — commit or stash them first."
    return 1
  fi

  mkdir -p "$POSTS_DIR"
  cp "$POST" "$DEST"
  git add "$DEST"
  git commit -m "Add: $SLUG post"
  git push --no-force
  echo "  ✅ Published to GitHub Pages: $SITE_URL/$SLUG"
}

publish_devto() {
  if [[ -z "${DEVTO_API_KEY:-}" ]]; then
    echo "❌ DEVTO_API_KEY is not set — cannot publish to dev.to."
    return 1
  fi

  # Extract title from frontmatter
  TITLE=$(python3 -c "
import re, sys
with open(sys.argv[1]) as f: content = f.read()
m = re.search(r'^title:\s*[\"\'](.*?)[\"\']', content, re.MULTILINE)
print(m.group(1) if m else 'Untitled')
" "$POST")

  # Convert markdown to plain body for dev.to API
  BODY_MD=$(sed '/^---$/,/^---$/d' "$POST")

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] Would POST to dev.to API: title='$TITLE'"
    return 0
  fi

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "https://dev.to/api/articles" \
    -H "api-key: ${DEVTO_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"article\":{\"title\":\"${TITLE}\",\"published\":true,\"body_markdown\":$(python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read()))" "$POST")}}")

  if [[ "$RESPONSE" == "201" ]]; then
    echo "  ✅ Published to dev.to: $TITLE"
  else
    echo "  ❌ dev.to API returned HTTP $RESPONSE"
    return 1
  fi
}

# Update bloom filter with new slugs (trigram hashes from post)
update_bloom() {
  python3 - "$POST" "$BLOOM_FILE" << 'PYEOF'
import re, sys, os
post_file  = sys.argv[1]
bloom_file = sys.argv[2]
with open(post_file) as f:
    body = f.read()
words = re.sub(r'[^a-z ]', ' ', body.lower()).split()
trigrams = [" ".join(words[i:i+3]) for i in range(len(words)-2)]
hashes = set(str(hash(tg)) for tg in trigrams)
existing = set()
if os.path.isfile(bloom_file):
    with open(bloom_file) as f:
        existing = set(f.read().splitlines())
with open(bloom_file, "a") as f:
    for h in hashes - existing:
        f.write(h + "\n")
PYEOF
}

case "$TARGET" in
  pages)
    publish_pages
    ;;
  devto)
    publish_devto
    ;;
  both)
    publish_pages
    publish_devto
    ;;
  *)
    echo "❌ Unknown target: $TARGET (use pages, devto, or both)"
    exit 1
    ;;
esac

if [[ "$DRY_RUN" == "false" ]]; then
  update_bloom
fi
