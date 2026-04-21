#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/skill-lib.sh
source "$ROOT_DIR/tools/skill-lib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-skill.sh [options] <skill-name>

Install a single ClawForge skill for a detected or selected variant.

Options:
  --variant <name>        Override automatic variant detection
  --dest <path>           Override the default target directory
  --force                 Overwrite an existing installed skill directory
  -h, --help              Show this help text
EOF
}

variant=""
dest_dir=""
force=0
skill=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --variant)
      variant="${2:-}"
      shift 2
      ;;
    --dest)
      dest_dir="${2:-}"
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
    -*)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ -n "$skill" ]; then
        echo "Only one skill name may be provided." >&2
        exit 1
      fi
      skill="$1"
      shift
      ;;
  esac
done

if [ -z "$skill" ]; then
  usage >&2
  exit 1
fi

variant="$(resolve_variant "${variant:-}")"
dest_dir="${dest_dir:-$(variant_skill_dir "$variant")}"

assert_known_skill "$skill"
assert_skill_supported "$skill" "$variant"

mkdir -p "$dest_dir"
install_skill_dir "$skill" "$dest_dir" "$force"

echo "Installed '$skill' for $(variant_label "$variant") into $dest_dir."
