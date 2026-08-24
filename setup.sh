#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
expected_dir="$config_home/quickshell/xfce-catppuccin"

if [[ "$project_dir" != "$expected_dir" ]]; then
    printf '%s\n' "This repository must be cloned to: $expected_dir" >&2
    printf '%s\n' "See the Installation section in README.md." >&2
    exit 1
fi

for command_name in qs make cc wmctrl xprop curl plocate xfconf-query; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
done

make -C "$project_dir"

printf '%s\n' 'Setup complete.'
printf '%s\n' 'Start it now with: qs -c xfce-catppuccin'
printf '%s\n' 'After testing, run ./enable-autostart.sh if you want it at login.'
printf '%s\n' 'XFCE components have not been disabled or removed.'
