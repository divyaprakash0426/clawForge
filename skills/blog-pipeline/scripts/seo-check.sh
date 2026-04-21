#!/usr/bin/env bash
# SEO score (0-100) and uniqueness check for a Markdown blog post
set -euo pipefail

POST="${1:-}"
if [[ -z "$POST" || ! -f "$POST" ]]; then
  echo "Usage: seo-check.sh <post.md>"
  exit 1
fi

BLOOM_FILE="${HOME}/.blog-pipeline/published.bloom"
mkdir -p "$HOME/.blog-pipeline"

python3 - "$POST" "$BLOOM_FILE" << 'PYEOF'
import sys, re, os
from math import ceil

post_file  = sys.argv[1]
bloom_file = sys.argv[2]

with open(post_file) as f:
    content = f.read()

# ── Parse frontmatter ────────────────────────────────────────────────────────
fm_match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
fm_fields = {}
body = content
if fm_match:
    for line in fm_match.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            fm_fields[k.strip()] = v.strip().strip('"\'')
    body = content[fm_match.end():]

title       = fm_fields.get("title", "")
description = fm_fields.get("description", "")
tags_raw    = fm_fields.get("tags", "")
# Try to extract a focus keyword from tags
tags = re.sub(r'[\[\]]', '', tags_raw).split(",")
keyword     = tags[0].strip().lower() if tags else ""

# ── Scoring ──────────────────────────────────────────────────────────────────
score = 0
notes = []

# Title length (20 pts)
tlen = len(title)
if 50 <= tlen <= 60:
    score += 20
    notes.append(f"✅ Title ({tlen} chars)")
elif 40 <= tlen <= 70:
    score += 12
    notes.append(f"⚠️  Title ({tlen} chars — ideal: 50–60)")
else:
    notes.append(f"❌ Title ({tlen} chars — ideal: 50–60)")

# Meta description length (20 pts)
dlen = len(description)
if 120 <= dlen <= 160:
    score += 20
    notes.append(f"✅ Meta description ({dlen} chars)")
elif 100 <= dlen <= 180:
    score += 12
    notes.append(f"⚠️  Meta description ({dlen} chars — ideal: 120–160)")
else:
    notes.append(f"❌ Meta description ({dlen} chars — ideal: 120–160)")

# Keyword in title (20 pts)
if keyword and keyword in title.lower():
    score += 20
    notes.append(f'✅ Keyword in title  "{keyword}"')
elif keyword:
    notes.append(f'❌ Keyword missing from title  "{keyword}"')

# Keyword in first paragraph (20 pts)
paragraphs = [p.strip() for p in re.split(r'\n\n+', body) if p.strip()]
first_para = paragraphs[0].lower() if paragraphs else ""
if keyword and keyword in first_para:
    score += 20
    notes.append(f'✅ Keyword in first paragraph')
elif keyword:
    notes.append(f'❌ Keyword missing from first paragraph')

# Keyword in an H2 heading (20 pts)
h2s = re.findall(r'^## (.+)', body, re.MULTILINE)
if keyword and any(keyword in h.lower() for h in h2s):
    score += 20
    notes.append(f'✅ Keyword in H2 heading')
elif keyword:
    notes.append(f'❌ Keyword not found in any H2 heading')

# Reading time estimate (informational)
words = len(re.sub(r'[^a-zA-Z ]', ' ', body).split())
reading_min = ceil(words / 200)

# ── Uniqueness scan ──────────────────────────────────────────────────────────
# Simple 3-gram frequency check against locally stored past slugs
# (bloom_file is a plaintext list of 3-gram hashes from past posts)
body_words = re.sub(r'[^a-z ]', ' ', body.lower()).split()
trigrams = [" ".join(body_words[i:i+3]) for i in range(len(body_words)-2)]
unique_note = "✅  no over-recycled phrases detected"
if os.path.isfile(bloom_file) and os.path.getsize(bloom_file) > 0:
    with open(bloom_file) as f:
        past_hashes = set(f.read().splitlines())
    recycled = sum(1 for tg in trigrams if str(hash(tg)) in past_hashes)
    if recycled > 3:
        unique_note = f"⚠️  {recycled} phrase(s) found in past posts — consider refreshing content"

# ── Output ────────────────────────────────────────────────────────────────────
print(f"\n📝 blog-pipeline SEO check  {post_file}\n")
for n in notes:
    print(f"  {n}")
print(f"  Reading time             : ~{reading_min} min")
print(f"  Uniqueness               : {unique_note}")
print(f"\n  SEO score : {score} / 100")

if score < 40:
    print("\n  ❌ Score below 40 — post needs significant SEO work before publishing.")
    sys.exit(2)
elif score < 60:
    print("\n  ⚠️  Score below 60 — consider improving before publishing.")
else:
    print("\n  ✅ Ready to publish.")
PYEOF
