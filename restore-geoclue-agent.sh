#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
rm -f "$config_home/autostart/geoclue-demo-agent.desktop"

if ! pgrep -f '^/usr/libexec/geoclue-2.0/demos/agent$' >/dev/null 2>&1; then
    /usr/libexec/geoclue-2.0/demos/agent >/dev/null 2>&1 &
fi

printf '%s\n' 'The GeoClue agent has been restored.'
