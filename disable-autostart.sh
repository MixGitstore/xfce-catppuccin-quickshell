#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
autostart_file="$config_home/autostart/quickshell-catppuccin.desktop"

if [[ -e "$autostart_file" ]]; then
    rm -- "$autostart_file"
fi

printf '%s\n' 'Quickshell autostart has been disabled. The configuration was kept.'
