#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "arch-sentry requires pacman." >&2
  exit 1
fi

cache_size="unknown"
if [ -d /var/cache/pacman/pkg ]; then
  cache_size="$(du -sh /var/cache/pacman/pkg | awk '{print $1}')"
fi

orphans_tmp="$(mktemp)"
if pacman -Qtdq >"$orphans_tmp" 2>/dev/null; then
  :
else
  status=$?
  if [ "$status" -ne 1 ]; then
    rm -f "$orphans_tmp"
    echo "pacman orphan check failed with status $status." >&2
    exit "$status"
  fi
fi

mapfile -t orphan_packages < <(sed '/^$/d' "$orphans_tmp")
rm -f "$orphans_tmp"

mapfile -t pacnew_files < <(find /etc -type f \( -name '*.pacnew' -o -name '*.pacsave' \) 2>/dev/null | sort)

printf '{\n'
printf '  "cache_size": "%s",\n' "$cache_size"
printf '  "orphan_count": %s,\n' "${#orphan_packages[@]}"
printf '  "orphan_packages": ['
for index in "${!orphan_packages[@]}"; do
  if [ "$index" -gt 0 ]; then
    printf ', '
  fi
  printf '"%s"' "${orphan_packages[$index]}"
done
printf '],\n'
printf '  "pacnew_count": %s,\n' "${#pacnew_files[@]}"
printf '  "pacnew_files": ['
for index in "${!pacnew_files[@]}"; do
  if [ "$index" -gt 0 ]; then
    printf ', '
  fi
  printf '"%s"' "${pacnew_files[$index]}"
done
printf ']\n'
printf '}\n'
