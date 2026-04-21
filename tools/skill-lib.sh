#!/usr/bin/env bash
set -euo pipefail

CLAWFORGE_VARIANTS=(openclaw zeroclaw picoclaw nullclaw nanobot ironclaw)

clawforge_root() {
  CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

variant_binary() {
  case "$1" in
    openclaw) echo "openclaw" ;;
    zeroclaw) echo "zeroclaw" ;;
    picoclaw) echo "picoclaw" ;;
    nullclaw) echo "nullclaw" ;;
    nanobot) echo "nanobot" ;;
    ironclaw) echo "ironclaw" ;;
    *)
      echo "Unknown variant: $1" >&2
      return 1
      ;;
  esac
}

variant_label() {
  case "$1" in
    openclaw) echo "OpenClaw" ;;
    zeroclaw) echo "ZeroClaw" ;;
    picoclaw) echo "PicoClaw" ;;
    nullclaw) echo "NullClaw" ;;
    nanobot) echo "NanoBot" ;;
    ironclaw) echo "IronClaw" ;;
    *)
      echo "Unknown variant: $1" >&2
      return 1
      ;;
  esac
}

variant_skill_dir() {
  case "$1" in
    openclaw) echo "${HOME}/.openclaw/skills" ;;
    zeroclaw) echo "${HOME}/.zeroclaw/skills" ;;
    picoclaw) echo "${HOME}/.picoclaw/skills" ;;
    nullclaw) echo "${HOME}/.nullclaw/skills" ;;
    nanobot) echo "${HOME}/.nanobot/skills" ;;
    ironclaw) echo "${HOME}/.ironclaw/skills" ;;
    *)
      echo "Unknown variant: $1" >&2
      return 1
      ;;
  esac
}

normalize_variant() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
}

detect_variant() {
  local found=()
  local variant

  if [ -n "${CLAWFORGE_VARIANT:-}" ]; then
    normalize_variant "$CLAWFORGE_VARIANT"
    return 0
  fi

  for variant in "${CLAWFORGE_VARIANTS[@]}"; do
    if command -v "$(variant_binary "$variant")" >/dev/null 2>&1; then
      found+=("$variant")
    fi
  done

  case "${#found[@]}" in
    0)
      echo "Unable to detect a Claw variant in PATH. Use --variant to choose one." >&2
      return 1
      ;;
    1)
      echo "${found[0]}"
      ;;
    *)
      printf 'Multiple Claw variants were detected: %s. Use --variant to choose one.\n' "${found[*]}" >&2
      return 1
      ;;
  esac
}

resolve_variant() {
  local value="${1:-}"
  if [ -z "$value" ]; then
    value="$(detect_variant)"
  fi
  value="$(normalize_variant "$value")"
  require_valid_variant "$value"
  printf '%s\n' "$value"
}

require_valid_variant() {
  local wanted="$1"
  local variant
  for variant in "${CLAWFORGE_VARIANTS[@]}"; do
    if [ "$wanted" = "$variant" ]; then
      return 0
    fi
  done
  echo "Unsupported variant '$wanted'." >&2
  return 1
}

skill_file() {
  local root
  root="$(clawforge_root)"
  printf '%s/skills/%s/SKILL.md\n' "$root" "$1"
}

skill_dir() {
  local root
  root="$(clawforge_root)"
  printf '%s/skills/%s\n' "$root" "$1"
}

list_all_skills() {
  local root
  root="$(clawforge_root)"
  find "$root/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

assert_known_skill() {
  if [ ! -f "$(skill_file "$1")" ]; then
    echo "Unknown skill '$1'." >&2
    return 1
  fi
}

skill_scalar() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    BEGIN {in_frontmatter = 0}
    /^---$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      }
      exit
    }
    in_frontmatter && $1 == key ":" {
      $1 = ""
      sub(/^[[:space:]]+/, "")
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      print
      exit
    }
  ' "$file"
}

skill_variant_status() {
  local file="$1"
  local variant="$2"
  awk -v variant="$variant" '
    BEGIN {in_frontmatter = 0; in_compat = 0}
    /^---$/ {
      if (in_frontmatter == 0) {
        in_frontmatter = 1
        next
      }
      exit
    }
    in_frontmatter && $1 == "compat:" {
      in_compat = 1
      next
    }
    in_frontmatter && in_compat && $1 == variant ":" {
      print $2
      exit
    }
    in_frontmatter && in_compat && $0 !~ /^[[:space:]]+[a-z]+:[[:space:]]+/ {
      in_compat = 0
    }
  ' "$file"
}

compatible_skills_for_variant() {
  local variant="$1"
  local skill
  for skill in $(list_all_skills); do
    if skill_is_supported "$skill" "$variant"; then
      printf '%s\n' "$skill"
    fi
  done
}

skill_is_supported() {
  local skill="$1"
  local variant="$2"
  local status
  status="$(skill_variant_status "$(skill_file "$skill")" "$variant")"
  [ -n "$status" ] && [ "$status" != "unsupported" ]
}

assert_skill_supported() {
  local skill="$1"
  local variant="$2"
  local status
  status="$(skill_variant_status "$(skill_file "$skill")" "$variant")"
  if [ -z "$status" ]; then
    echo "Skill '$skill' is missing compatibility data for '$variant'." >&2
    return 1
  fi
  if [ "$status" = "unsupported" ]; then
    echo "Skill '$skill' is marked unsupported for $(variant_label "$variant")." >&2
    return 1
  fi
}

print_skill_listing() {
  local variant="$1"
  local skill
  local status
  local description
  local index=1

  echo "Compatible skills for $(variant_label "$variant"):"
  for skill in $(list_all_skills); do
    status="$(skill_variant_status "$(skill_file "$skill")" "$variant")"
    [ -n "$status" ] || continue
    [ "$status" = "unsupported" ] && continue
    description="$(skill_scalar "$(skill_file "$skill")" "description")"
    printf '  %2d. %-18s [%s] %s\n' "$index" "$skill" "$status" "$description"
    index=$((index + 1))
  done
}

read_csv_into_array() {
  local csv="$1"
  local array_name="$2"
  local cleaned
  local -a values=()

  cleaned="$(printf '%s' "$csv" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d')"
  while IFS= read -r line; do
    values+=("$line")
  done <<<"$cleaned"

  eval "$array_name=(\"\${values[@]}\")"
}

selection_to_skill_array() {
  local variant="$1"
  local selection="$2"
  local array_name="$3"
  local -a choices=()
  local -a resolved=()
  local -a compatible=()
  local item

  read_csv_into_array "$selection" choices
  mapfile -t compatible < <(compatible_skills_for_variant "$variant")

  for item in "${choices[@]}"; do
    if [[ "$item" =~ ^[0-9]+$ ]]; then
      if [ "$item" -lt 1 ] || [ "$item" -gt "${#compatible[@]}" ]; then
        echo "Selection '$item' is out of range." >&2
        return 1
      fi
      resolved+=("${compatible[$((item - 1))]}")
    else
      resolved+=("$item")
    fi
  done

  eval "$array_name=(\"\${resolved[@]}\")"
}

# ---------------------------------------------------------------------------
# Soul utility functions
# ---------------------------------------------------------------------------

soul_dir() {
  local root
  root="$(clawforge_root)"
  printf '%s/souls/%s\n' "$root" "$1"
}

soul_yaml_file() {
  printf '%s/soul.yaml\n' "$(soul_dir "$1")"
}

list_all_souls() {
  local root
  root="$(clawforge_root)"
  find "$root/souls" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

assert_known_soul() {
  if [ ! -f "$(soul_yaml_file "$1")" ]; then
    echo "Unknown soul '$1'." >&2
    return 1
  fi
}

variant_soul_dir() {
  case "$1" in
    openclaw) echo "${HOME}/.openclaw/souls" ;;
    zeroclaw) echo "${HOME}/.zeroclaw/souls" ;;
    picoclaw) echo "${HOME}/.picoclaw/souls" ;;
    nullclaw) echo "${HOME}/.nullclaw/souls" ;;
    nanobot) echo "${HOME}/.nanobot/souls" ;;
    ironclaw) echo "${HOME}/.ironclaw/souls" ;;
    *)
      echo "Unknown variant: $1" >&2
      return 1
      ;;
  esac
}

soul_yaml_compat_status() {
  local file="$1"
  local variant="$2"
  awk -v variant="$variant" '
    BEGIN {in_compat = 0}
    /^compat:/ { in_compat = 1; next }
    in_compat && /^[[:space:]]+[a-z]/ {
      line = $0
      gsub(/^[[:space:]]+/, "", line)
      key = substr(line, 1, index(line, ":") - 1)
      val = line
      sub(/^[^:]+:[[:space:]]*/, "", val)
      gsub(/[[:space:]]/, "", val)
      if (key == variant) { print val; exit }
    }
    in_compat && /^[^[:space:]]/ { in_compat = 0 }
  ' "$file"
}

soul_compat_status() {
  soul_yaml_compat_status "$(soul_yaml_file "$1")" "$2"
}

soul_is_supported() {
  local soul="$1"
  local variant="$2"
  local status
  status="$(soul_compat_status "$soul" "$variant")"
  [ -n "$status" ] && [ "$status" != "unsupported" ]
}

assert_soul_supported() {
  local soul="$1"
  local variant="$2"
  local status
  status="$(soul_compat_status "$soul" "$variant")"
  if [ -z "$status" ]; then
    echo "Soul '$soul' is missing compatibility data for '$variant'." >&2
    return 1
  fi
  if [ "$status" = "unsupported" ]; then
    echo "Soul '$soul' is marked unsupported for $(variant_label "$variant")." >&2
    return 1
  fi
}

soul_display_name() {
  awk '/^display_name:/ {sub(/^display_name:[[:space:]]*/, ""); print; exit}' "$(soul_yaml_file "$1")"
}

print_soul_listing() {
  local variant="$1"
  local soul
  local status
  local display_name
  local index=1

  echo "Available souls for $(variant_label "$variant"):"
  for soul in $(list_all_souls); do
    status="$(soul_compat_status "$soul" "$variant")"
    [ -n "$status" ] || continue
    [ "$status" = "unsupported" ] && continue
    display_name="$(soul_display_name "$soul")"
    printf '  %2d. %-22s [%s] %s\n' "$index" "$soul" "$status" "$display_name"
    index=$((index + 1))
  done
}

install_soul_dir() {
  local soul="$1"
  local dest_dir="$2"
  local force="$3"
  local source_dir
  local target_dir
  local backup_dir

  source_dir="$(soul_dir "$soul")"
  target_dir="${dest_dir}/${soul}"

  if [ -e "$target_dir" ]; then
    if [ "$force" -ne 1 ]; then
      echo "Soul '$soul' already exists at $target_dir. Re-run with --force to replace it." >&2
      return 1
    fi
    backup_dir="${target_dir}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target_dir" "$backup_dir"
    echo "Backed up existing '$soul' to $backup_dir"
  fi

  cp -R "$source_dir" "$target_dir"
}

# ---------------------------------------------------------------------------
install_skill_dir() {
  local skill="$1"
  local dest_dir="$2"
  local force="$3"
  local source_dir
  local target_dir
  local backup_dir

  source_dir="$(skill_dir "$skill")"
  target_dir="${dest_dir}/${skill}"

  if [ -e "$target_dir" ]; then
    if [ "$force" -ne 1 ]; then
      echo "Skill '$skill' already exists at $target_dir. Re-run with --force to replace it." >&2
      return 1
    fi
    backup_dir="${target_dir}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target_dir" "$backup_dir"
    echo "Backed up existing '$skill' to $backup_dir"
  fi

  cp -R "$source_dir" "$target_dir"
}
