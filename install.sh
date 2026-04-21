#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/skill-lib.sh
source "$ROOT_DIR/tools/skill-lib.sh"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install one or more ClawForge skills for a detected or selected variant.

Options:
  --variant <name>        Override automatic variant detection
  --skills <a,b,c>        Install the named comma-separated skills
  --all                   Install every compatible skill
  --dest <path>           Override the default target directory
  --force                 Overwrite existing installed skill directories
  --list                  Print compatible skills and exit
  -h, --help              Show this help text
EOF
}

variant=""
skills_arg=""
dest_dir=""
install_all=0
force=0
list_only=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --variant)
      variant="${2:-}"
      shift 2
      ;;
    --skills)
      skills_arg="${2:-}"
      shift 2
      ;;
    --dest)
      dest_dir="${2:-}"
      shift 2
      ;;
    --all)
      install_all=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --list)
      list_only=1
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

variant="$(resolve_variant "${variant:-}")"
dest_dir="${dest_dir:-$(variant_skill_dir "$variant")}"

mapfile -t compatible_skills < <(compatible_skills_for_variant "$variant")
if [ "${#compatible_skills[@]}" -eq 0 ]; then
  echo "No compatible skills were found for variant '$variant'." >&2
  exit 1
fi

if [ "$list_only" -eq 1 ]; then
  print_skill_listing "$variant"
  exit 0
fi

selected_skills=()

if [ "$install_all" -eq 1 ]; then
  selected_skills=("${compatible_skills[@]}")
elif [ -n "$skills_arg" ]; then
  read_csv_into_array "$skills_arg" selected_skills
else
  echo "Detected variant: $(variant_label "$variant")"
  echo "Install target: $dest_dir"
  echo
  print_skill_listing "$variant"
  echo
  echo "Enter skill names or numbers separated by commas."
  echo "Press Enter with no input to abort."
  read -r -p "> " selection
  if [ -z "${selection:-}" ]; then
    echo "No skills selected."
    exit 0
  fi
  selection_to_skill_array "$variant" "$selection" selected_skills
fi

if [ "${#selected_skills[@]}" -eq 0 ]; then
  echo "No skills selected." >&2
  exit 1
fi

mkdir -p "$dest_dir"
installed_count=0

for skill in "${selected_skills[@]}"; do
  assert_known_skill "$skill"
  assert_skill_supported "$skill" "$variant"
  install_skill_dir "$skill" "$dest_dir" "$force"
  installed_count=$((installed_count + 1))
done

echo
echo "Installed $installed_count skill(s) for $(variant_label "$variant") into $dest_dir:"
for skill in "${selected_skills[@]}"; do
  printf '  - %s\n' "$skill"
done
