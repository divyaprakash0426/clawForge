---
name: blog-pipeline
description: Draft-to-publish blog pipeline with markdown-first publishing targets.
version: 1.0.0
metadata:
  openclaw:
    emoji: "✍️"
    requires:
      bins: ["git", "gh", "pandoc", "curl", "jq"]
      env: ["GITHUB_TOKEN", "SITE_URL"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L2
    tags: ["creative", "blog", "publishing", "seo"]
---

# blog-pipeline

## Purpose

Move a Markdown draft through quality gates — SEO check, uniqueness scan, link
validation — and publish to GitHub Pages and/or dev.to with a single workflow.
All gates run locally; only the final publish step touches external APIs.

## Runbook

1. **Pre-flight** — verify `git`, `gh`, `pandoc`, `curl`, and `jq` are available.  
   `GITHUB_TOKEN` is required for GitHub Pages push.  
   `DEVTO_API_KEY` is optional; set it only when publishing to dev.to.

2. **Lint the draft** — run `scripts/lint-draft.sh <post.md>`:
   - Checks frontmatter for `title`, `description`, `tags`, `date`
   - Validates internal links resolve (relative paths)
   - Warns on images without `alt` text
   - Enforces line length ≤ 120 chars for diff readability
   - Exit 1 on any error; exit 0 with warnings printed to stdout

3. **SEO check** — run `scripts/seo-check.sh <post.md>`:
   - Title: 50–60 chars recommended
   - Meta description: 120–160 chars
   - Checks that the focus keyword appears in title, first paragraph, and at least
     one H2 heading
   - Counts reading-time estimate (≈200 wpm)
   - Prints a scored report (0–100); score < 60 prints a blocking warning

4. **Uniqueness scan** — `scripts/seo-check.sh` also extracts 3-gram phrases and
   checks them against a local bloom-filter of your past posts
   (`~/.blog-pipeline/published.bloom`). Flags phrases appearing in > 3 prior
   posts as potentially over-recycled.

5. **Publish** — run `scripts/publish.sh <post.md> [--target pages|devto|both]`:
   - GitHub Pages: copies to `_posts/` in the configured repo, commits, and pushes
   - dev.to: POSTs to `https://dev.to/api/articles` using `DEVTO_API_KEY`
   - Default `--target` is `pages` only
   - Dry-run mode: `--dry-run` prints the actions without executing them

6. **Post-publish** — appends the article slug to
   `~/.blog-pipeline/published.bloom` for future uniqueness checks.

## Stop conditions

1. Abort if `GITHUB_TOKEN` is unset and target includes `pages`.
2. Abort if `DEVTO_API_KEY` is unset and target includes `devto`.
3. Abort if lint-draft exits 1 — fix frontmatter or broken links first.
4. Abort if SEO score < 40 — post needs more work.
5. Never force-push the GitHub Pages branch; always `--no-force`.
6. Do not publish if `git status` shows uncommitted changes in the posts directory.

## Output format

### Lint report (stdout)
```
✅ Frontmatter  OK
✅ Internal links  OK  (4 checked)
⚠️  Image alt text  MISSING on 1 image  →  line 42
✅ Line length  OK
```

### SEO report (stdout)
```
📝 blog-pipeline SEO check
Title (58 chars)         : ✅
Meta description (142)   : ✅
Keyword in title         : ✅ "HRV"
Keyword in first para    : ✅
Keyword in H2            : ✅
Reading time             : ~6 min
Uniqueness               : ✅  no over-recycled phrases
SEO score                : 78 / 100
```

### Publish summary (stdout)
```
✍️ blog-pipeline publish
Target  : GitHub Pages
Post    : _posts/2026-04-22-hrv-guide.md
Commit  : abc1234  "Add: HRV guide post"
Push    : ✅ origin/gh-pages
URL     : https://yoursite.com/hrv-guide
```

## Example invocations

- `scripts/lint-draft.sh my-post.md` — validate frontmatter and links
- `scripts/seo-check.sh my-post.md` — score SEO and uniqueness
- `scripts/publish.sh my-post.md --target pages` — push to GitHub Pages
- `scripts/publish.sh my-post.md --target both --dry-run` — preview actions
- "Check my draft for SEO issues."
- "Publish this post to dev.to."
