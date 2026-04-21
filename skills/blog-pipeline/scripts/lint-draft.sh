#!/usr/bin/env bash
# Validate a Markdown blog post: frontmatter, internal links, image alt text
set -euo pipefail

POST="${1:-}"
if [[ -z "$POST" || ! -f "$POST" ]]; then
  echo "Usage: lint-draft.sh <post.md>"
  exit 1
fi

python3 - "$POST" << 'PYEOF'
import sys, re, os

post_file = sys.argv[1]
post_dir  = os.path.dirname(os.path.abspath(post_file))

with open(post_file) as f:
    content = f.read()

errors   = []
warnings = []

# ── Frontmatter ─────────────────────────────────────────────────────────────
fm_match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if not fm_match:
    errors.append("Frontmatter missing or malformed (expected YAML block at top)")
    fm_fields = {}
else:
    fm_text = fm_match.group(1)
    fm_fields = {}
    for line in fm_text.splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            fm_fields[k.strip()] = v.strip()

    for required in ("title", "description", "tags", "date"):
        if required not in fm_fields or not fm_fields[required]:
            errors.append(f"Frontmatter missing required field: {required}")

# ── Internal links ───────────────────────────────────────────────────────────
md_links = re.findall(r'\[.*?\]\(([^)]+)\)', content)
link_errors = 0
for link in md_links:
    if link.startswith("http") or link.startswith("#"):
        continue  # skip external and anchor links
    target = os.path.join(post_dir, link)
    if not os.path.exists(target):
        errors.append(f"Broken internal link: {link}")
        link_errors += 1

# ── Image alt text ───────────────────────────────────────────────────────────
images = re.findall(r'!\[(.*?)\]\(', content)
missing_alt = sum(1 for alt in images if not alt.strip())
if missing_alt:
    warnings.append(f"Image alt text MISSING on {missing_alt} image(s) — check accessibility")

# ── Line length ──────────────────────────────────────────────────────────────
long_lines = [i+1 for i, line in enumerate(content.splitlines()) if len(line) > 120]
if long_lines:
    warnings.append(f"Lines exceeding 120 chars: {long_lines[:5]}{'...' if len(long_lines) > 5 else ''}")

# ── Output ───────────────────────────────────────────────────────────────────
print(f"\n✍️  blog-pipeline — lint  {post_file}\n")

status_fm = "❌" if any("Frontmatter" in e for e in errors) else "✅"
status_links = "❌" if link_errors else "✅"
alt_status = "⚠️ " if missing_alt else "✅"
len_status = "⚠️ " if long_lines else "✅"

print(f"  {status_fm} Frontmatter")
print(f"  {status_links} Internal links  ({len([l for l in md_links if not l.startswith('http') and not l.startswith('#')])} checked)")
print(f"  {alt_status} Image alt text")
print(f"  {len_status} Line length")

if errors:
    print()
    for e in errors:
        print(f"  ❌ {e}")

if warnings:
    print()
    for w in warnings:
        print(f"  ⚠️  {w}")

if errors:
    print()
    print("Fix errors before publishing.")
    sys.exit(1)

print("\n  ✅ Lint passed — ready for SEO check.")
PYEOF
