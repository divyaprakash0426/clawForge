#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: ./tools/forge-skill.sh [options]

Interactive skill scaffolder for ClawForge. Options may be supplied to run non-interactively.

Options:
  --name <skill-name>
  --description <text>
  --domain <devops|security|research|productivity|health|creative|finance>
  --emoji <emoji>
  --bins <a,b,c>
  --env <A,B,C>
  --tier <L1|L2|L3>
  --tags <a,b,c>
  --compat <openclaw=full,zeroclaw=full,picoclaw=partial,nullclaw=unsupported,nanobot=full,ironclaw=partial>
  --force
  -h, --help
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

while [ "$#" -gt 0 ]; do
  case "$1" in
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

if [ -z "$name" ]; then
  name="$(prompt_default "Skill name")"
fi

if [ -z "$description" ]; then
  description="$(prompt_default "Description")"
fi

if [ -z "$domain" ]; then
  domain="$(prompt_default "Domain" "devops")"
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

if [ "$tags_supplied" -eq 0 ]; then
  tags="$(prompt_default "Tags (comma-separated)" "$domain")"
fi

name="$(slugify "$name")"

case "$domain" in
  devops|security|research|productivity|health|creative|finance) ;;
  *)
    echo "Unsupported domain '$domain'." >&2
    exit 1
    ;;
esac

case "$tier" in
  L1|L2|L3) ;;
  *)
    echo "Security tier must be one of L1, L2, or L3." >&2
    exit 1
    ;;
esac

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

skill_dir="${ROOT_DIR}/skills/${name}"

if [ -e "$skill_dir" ] && [ "$force" -ne 1 ]; then
  echo "Skill directory already exists: $skill_dir" >&2
  exit 1
fi

rm -rf "$skill_dir"
mkdir -p "$skill_dir/scripts"

bins_yaml="$(csv_to_yaml_array "$required_bins")"
env_yaml="$(csv_to_yaml_array "$required_env")"
tags_yaml="$(csv_to_yaml_array "$tags")"

cat >"$skill_dir/SKILL.md" <<EOF
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

cat >"$skill_dir/README.md" <<EOF
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

cat >"$skill_dir/COMPAT.md" <<EOF
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

cat >"$skill_dir/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "No additional setup steps are defined for this skill yet."
echo "Document required dependencies in SKILL.md before expanding this installer."
EOF

cat >"$skill_dir/scripts/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "This skill scaffold does not have an executable helper yet."
echo "Use the runbook in SKILL.md to implement the concrete workflow."
EOF

chmod +x "$skill_dir/install.sh" "$skill_dir/scripts/run.sh"

echo "Scaffolded skill: $name"
