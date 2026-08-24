#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}

mkdir -p "$config_home/autostart"
install -m 0644 \
    "$project_dir/autostart/quickshell-catppuccin.desktop" \
    "$config_home/autostart/quickshell-catppuccin.desktop"

printf '%s\n' 'Quickshell autostart has been enabled.'
printf '%s\n' 'The XFCE panel is still enabled for safe side-by-side testing.'
