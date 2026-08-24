#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
mkdir -p "$config_home/autostart"

printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=Clipman (replaced by Quickshell)' \
    'Hidden=true' \
    > "$config_home/autostart/xfce4-clipman-plugin-autostart.desktop"

pkill -x xfce4-clipman 2>/dev/null || true
printf '%s\n' 'Clipman autostart has been disabled; the package was kept.'
