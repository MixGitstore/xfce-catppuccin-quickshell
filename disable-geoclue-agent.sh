#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
mkdir -p "$config_home/autostart"

printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=GeoClue Demo Agent (not needed for fixed weather coordinates)' \
    'Hidden=true' \
    > "$config_home/autostart/geoclue-demo-agent.desktop"

pkill -f '^/usr/libexec/geoclue-2.0/demos/agent$' 2>/dev/null || true
printf '%s\n' 'GeoClue demo-agent autostart has been disabled; GeoClue was kept.'
