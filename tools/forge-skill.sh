#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: ./tools/forge-skill.sh [options]

Interactive skill/soul scaffolder for ClawForge. Options may be supplied to run non-interactively.

Common options:
  --type <skill|soul>     Artifact type to scaffold (default: skill)
  --name <name>
  --domain <devops|security|research|productivity|health|creative|finance>
  --tags <a,b,c>
  --compat <openclaw=full,zeroclaw=full,picoclaw=partial,nullclaw=unsupported,nanobot=full,ironclaw=partial>
  --force
  -h, --help

Skill-only options:
  --description <text>
  --emoji <emoji>
  --bins <a,b,c>
  --env <A,B,C>
  --tier <L1|L2|L3>

Soul-only options:
  --display-name <text>
  --tone <terse|balanced|verbose>
  --activate-skills <a,b,c>
  --preferred-output <structured|prose|raw>
  --tier-cap <L1|L2|L3>
EOF
}

slugify() {
  printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

prompt_default() {
  local prompt="$1"
  local default="${2:-}"
  local reply

  if [ -n "$default" ]; then
    read -r -p "$prompt [$default]: " reply
    printf '%s\n' "${reply:-$default}"
  else
    read -r -p "$prompt: " reply
    printf '%s\n' "$reply"
  fi
}

csv_to_yaml_array() {
  local raw="${1:-}"
  local cleaned
  local first=1
  local output="["

  cleaned="$(printf '%s' "$raw" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d')"
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    if [ "$first" -eq 0 ]; then
      output+=", "
    fi
    output+="\"$item\""
    first=0
  done <<<"$cleaned"
  output+="]"
  printf '%s\n' "$output"
}

default_emoji_for_domain() {
  case "$1" in
    devops) echo "🛠️" ;;
    security) echo "🛡️" ;;
    research) echo "📚" ;;
    productivity) echo "📅" ;;
    health) echo "🏸" ;;
    creative) echo "🎬" ;;
    finance) echo "📈" ;;
    *) echo "🦞" ;;
  esac
}

parse_compat_value() {
  local compat_string="$1"
  local variant="$2"
  printf '%s\n' "$compat_string" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | awk -F= -v variant="$variant" '$1 == variant {print $2; exit}'
}

validate_status() {
  case "$1" in
    full|partial|unsupported) ;;
    *)
      echo "Invalid compatibility status '$1'." >&2
      exit 1
      ;;
  esac
}

name=""
description=""
domain=""
emoji=""
required_bins=""
required_env=""
tier=""
tags=""
compat="openclaw=full,zeroclaw=full,picoclaw=partial,nullclaw=unsupported,nanobot=full,ironclaw=partial"
force=0
bins_supplied=0
env_supplied=0
tags_supplied=0
artifact_type=""
display_name=""
tone=""
activate_skills=""
preferred_output=""
tier_cap=""
activate_skills_supplied=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --type)
      artifact_type="${2:-}"
      shift 2
      ;;
    --name)
      name="${2:-}"
      shift 2
      ;;
    --description)
      description="${2:-}"
      shift 2
      ;;
    --domain)
      domain="${2:-}"
      shift 2
      ;;
    --emoji)
      emoji="${2:-}"
      shift 2
      ;;
    --bins)
      required_bins="${2:-}"
      bins_supplied=1
      shift 2
      ;;
    --env)
      required_env="${2:-}"
      env_supplied=1
      shift 2
      ;;
    --tier)
      tier="${2:-}"
      shift 2
      ;;
    --tags)
      tags="${2:-}"
      tags_supplied=1
      shift 2
      ;;
    --compat)
      compat="${2:-}"
      shift 2
      ;;
    --display-name)
      display_name="${2:-}"
      shift 2
      ;;
    --tone)
      tone="${2:-}"
      shift 2
      ;;
    --activate-skills)
      activate_skills="${2:-}"
      activate_skills_supplied=1
      shift 2
      ;;
    --preferred-output)
      preferred_output="${2:-}"
      shift 2
      ;;
    --tier-cap)
      tier_cap="${2:-}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$artifact_type" ]; then
  artifact_type="$(prompt_default "Type [skill/soul]" "skill")"
fi

case "$artifact_type" in
  skill|soul) ;;
  *)
    echo "Type must be 'skill' or 'soul'." >&2
    exit 1
    ;;
esac

if [ -z "$name" ]; then
  name="$(prompt_default "${artifact_type^} name")"
fi

if [ -z "$domain" ]; then
  domain="$(prompt_default "Domain" "devops")"
fi

case "$domain" in
  devops|security|research|productivity|health|creative|finance) ;;
  *)
    echo "Unsupported domain '$domain'." >&2
    exit 1
    ;;
esac

if [ "$tags_supplied" -eq 0 ]; then
  tags="$(prompt_default "Tags (comma-separated)" "$domain")"
fi

name="$(slugify "$name")"

openclaw_status="$(parse_compat_value "$compat" "openclaw")"
zeroclaw_status="$(parse_compat_value "$compat" "zeroclaw")"
picoclaw_status="$(parse_compat_value "$compat" "picoclaw")"
nullclaw_status="$(parse_compat_value "$compat" "nullclaw")"
nanobot_status="$(parse_compat_value "$compat" "nanobot")"
ironclaw_status="$(parse_compat_value "$compat" "ironclaw")"

validate_status "$openclaw_status"
validate_status "$zeroclaw_status"
validate_status "$picoclaw_status"
validate_status "$nullclaw_status"
validate_status "$nanobot_status"
validate_status "$ironclaw_status"

# ── Soul scaffolding ─────────────────────────────────────────────────────────
if [ "$artifact_type" = "soul" ]; then
  if [ -z "$display_name" ]; then
    display_name="$(prompt_default "Display name" "$name")"
  fi

  if [ -z "$tone" ]; then
    tone="$(prompt_default "Tone [terse/balanced/verbose]" "balanced")"
  fi

  case "$tone" in
    terse|balanced|verbose) ;;
    *)
      echo "Tone must be one of terse, balanced, or verbose." >&2
      exit 1
      ;;
  esac

  if [ "$activate_skills_supplied" -eq 0 ]; then
    activate_skills="$(prompt_default "Activate skills (comma-separated)" "")"
  fi

  if [ -z "$preferred_output" ]; then
    preferred_output="$(prompt_default "Preferred output [structured/prose/raw]" "structured")"
  fi

  case "$preferred_output" in
    structured|prose|raw) ;;
    *)
      echo "Preferred output must be one of structured, prose, or raw." >&2
      exit 1
      ;;
  esac

  if [ -z "$tier_cap" ]; then
    tier_cap="$(prompt_default "Security tier cap [L1/L2/L3]" "L3")"
  fi

  case "$tier_cap" in
    L1|L2|L3) ;;
    *)
      echo "Security tier cap must be one of L1, L2, or L3." >&2
      exit 1
      ;;
  esac

  soul_dir="${ROOT_DIR}/souls/${name}"

  if [ -e "$soul_dir" ] && [ "$force" -ne 1 ]; then
    echo "Soul directory already exists: $soul_dir" >&2
    exit 1
  fi

  rm -rf "$soul_dir"
  mkdir -p "$soul_dir"

  tags_yaml="$(csv_to_yaml_array "$tags")"

  # Build activate_skills as a YAML list
  skills_list=""
  if [ -n "$activate_skills" ]; then
    cleaned_skills="$(printf '%s' "$activate_skills" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d')"
    while IFS= read -r skill_item; do
      [ -n "$skill_item" ] || continue
      skills_list="${skills_list}  - ${skill_item}"$'\n'
    done <<<"$cleaned_skills"
  fi
  if [ -z "$skills_list" ]; then
    skills_list="  []"$'\n'
  fi

  cat >"$soul_dir/soul.yaml" <<EOF
name: $name
display_name: $display_name
version: 1.0.0
author: clawforge-maintainers
domain: $domain
tone: $tone
activate_skills:
${skills_list}preferred_output: $preferred_output
security_tier_cap: $tier_cap
tags: $tags_yaml
compat:
  openclaw: $openclaw_status
  zeroclaw: $zeroclaw_status
  picoclaw: $picoclaw_status
  nullclaw: $nullclaw_status
  nanobot: $nanobot_status
  ironclaw: $ironclaw_status
EOF

  cat >"$soul_dir/SOUL.md" <<EOF
---
name: $name
version: 1.0.0
---

## Identity

Describe the operator context and perspective this soul embodies in one paragraph.

## Default behaviors

- List always-on behaviors here (output format, verbosity, confirmation gates).

## Activated skills

| Skill | Why |
| --- | --- |
| \`example-skill\` | Describe why this skill is always loaded for this persona. |

## Domain vocabulary

- **Term**: Definition relevant to this domain.

## Stop conditions

- Pause and require confirmation before taking irreversible actions.
- Pause if any activated skill returns a high-severity finding.

## Example invocations

Describe 2–3 annotated prompts showing this soul in practice.
EOF

  echo "Scaffolded soul: $name"
  exit 0
fi
# ── End soul scaffolding ─────────────────────────────────────────────────────

# ── Skill scaffolding ────────────────────────────────────────────────────────
if [ -z "$description" ]; then
  description="$(prompt_default "Description")"
fi

if [ -z "$emoji" ]; then
  emoji="$(default_emoji_for_domain "$domain")"
fi

if [ "$bins_supplied" -eq 0 ]; then
  required_bins="$(prompt_default "Required bins (comma-separated)" "")"
fi

if [ "$env_supplied" -eq 0 ]; then
  required_env="$(prompt_default "Required env vars (comma-separated)" "")"
fi

if [ -z "$tier" ]; then
  tier="$(prompt_default "Security tier" "L1")"
fi

case "$tier" in
  L1|L2|L3) ;;
  *)
    echo "Security tier must be one of L1, L2, or L3." >&2
    exit 1
    ;;
esac

skill_dir_path="${ROOT_DIR}/skills/${name}"

if [ -e "$skill_dir_path" ] && [ "$force" -ne 1 ]; then
  echo "Skill directory already exists: $skill_dir_path" >&2
  exit 1
fi

rm -rf "$skill_dir_path"
mkdir -p "$skill_dir_path/scripts"

bins_yaml="$(csv_to_yaml_array "$required_bins")"
env_yaml="$(csv_to_yaml_array "$required_env")"
tags_yaml="$(csv_to_yaml_array "$tags")"

cat >"$skill_dir_path/SKILL.md" <<EOF
---
name: $name
description: $description
version: 1.0.0
metadata:
  openclaw:
    emoji: "$emoji"
    requires:
      bins: $bins_yaml
      env: $env_yaml
    primaryEnv: null
    compat:
      openclaw: $openclaw_status
      zeroclaw: $zeroclaw_status
      picoclaw: $picoclaw_status
      nullclaw: $nullclaw_status
      nanobot: $nanobot_status
      ironclaw: $ironclaw_status
    security_tier: $tier
    tags: $tags_yaml
---

# $name

## Purpose

$description

## Runbook

1. Confirm the required binaries and environment variables are available.
2. Review the compatibility notes for the current variant before execution.
3. Run the helper scripts in \`scripts/\` or translate the steps into your Claw variant's preferred workflow.
4. Capture the resulting output in a structured summary for the operator.

## Stop conditions

1. Abort if required dependencies are missing.
2. Abort if the active variant is marked \`unsupported\`.
3. Abort before any destructive action that is not clearly documented.

## Output format

- Summary
- Findings
- Recommended next actions

## Example invocations

- "Run $name against the current project"
- "Summarize the output of $name for today's workflow"
EOF

cat >"$skill_dir_path/README.md" <<EOF
# $name

## What it does

$description

## Directory contents

- \`SKILL.md\` — machine-readable skill metadata and runbook
- \`COMPAT.md\` — compatibility notes for each Claw variant
- \`install.sh\` — optional one-time setup for local dependencies
- \`scripts/run.sh\` — placeholder execution entrypoint

## Suggested workflow

1. Review the frontmatter for required binaries, environment variables, and security tier.
2. Read \`COMPAT.md\` before enabling the skill on a constrained or sandboxed variant.
3. Adjust \`scripts/run.sh\` to fit your actual environment and integrations.
EOF

cat >"$skill_dir_path/COMPAT.md" <<EOF
# Compatibility notes for $name

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | $openclaw_status | Review runtime-specific helper scripts before execution. |
| ZeroClaw | $zeroclaw_status | Shell-driven workflows generally port well when dependencies exist. |
| PicoClaw | $picoclaw_status | Lightweight devices may need reduced automation scope. |
| NullClaw | $nullclaw_status | Embedded execution is limited; prefer read-only or summary workflows. |
| NanoBot | $nanobot_status | Python-friendly environments work well for API or data tasks. |
| IronClaw | $ironclaw_status | Sandboxed execution may block direct shell or network actions. |
EOF

cat >"$skill_dir_path/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "No additional setup steps are defined for this skill yet."
echo "Document required dependencies in SKILL.md before expanding this installer."
EOF

cat >"$skill_dir_path/scripts/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "This skill scaffold does not have an executable helper yet."
echo "Use the runbook in SKILL.md to implement the concrete workflow."
EOF

chmod +x "$skill_dir_path/install.sh" "$skill_dir_path/scripts/run.sh"

echo "Scaffolded skill: $name"
