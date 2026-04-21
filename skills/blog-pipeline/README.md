# blog-pipeline ✍️

> Draft → lint → SEO-check → publish to GitHub Pages or dev.to.

## What it does

`blog-pipeline` runs a Markdown blog post through a series of quality gates
(frontmatter lint, SEO score, uniqueness check) and then publishes it to GitHub
Pages and/or dev.to via their APIs. Each gate can be run independently or as a
full pipeline.

## Setup

```bash
# One-time install (creates ~/.blog-pipeline/, checks deps)
bash skills/blog-pipeline/install.sh

# Required env vars
export GITHUB_TOKEN="ghp_..."          # for GitHub Pages push
export SITE_URL="https://yoursite.com" # used in publish summary

# Optional — only needed for dev.to publishing
export DEVTO_API_KEY="your-api-key"
```

## Quickstart

```bash
# Lint frontmatter and internal links
bash skills/blog-pipeline/scripts/lint-draft.sh my-post.md

# Run SEO check and uniqueness scan
bash skills/blog-pipeline/scripts/seo-check.sh my-post.md

# Publish to GitHub Pages
bash skills/blog-pipeline/scripts/publish.sh my-post.md --target pages

# Dry run — see what would happen without making changes
bash skills/blog-pipeline/scripts/publish.sh my-post.md --target both --dry-run
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and runbook |
| `COMPAT.md` | Per-variant notes |
| `install.sh` | Check deps, create `~/.blog-pipeline/` config directory |
| `scripts/lint-draft.sh` | Validate frontmatter, internal links, image alt text |
| `scripts/seo-check.sh` | Score SEO (0–100), flag keyword gaps, uniqueness scan |
| `scripts/publish.sh` | Push to GitHub Pages and/or post to dev.to API |

## Required frontmatter

```yaml
---
title: "Your Post Title Here"
description: "A 120–160 character meta description."
tags: [tag1, tag2]
date: "2026-04-22"
---
```

## SEO score breakdown

| Check | Weight |
|-------|--------|
| Title length 50–60 chars | 20 pts |
| Meta description 120–160 chars | 20 pts |
| Focus keyword in title | 20 pts |
| Focus keyword in first paragraph | 20 pts |
| Focus keyword in ≥ 1 H2 | 20 pts |

Score < 60 prints a warning. Score < 40 blocks publish.

## Security tier: L2

Reads Markdown files locally. Outbound HTTPS to GitHub API and dev.to API only
when `--target` is specified. Credentials are read from env vars — never
committed to the repo.

