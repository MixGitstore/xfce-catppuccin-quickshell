#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
rm -f "$config_home/autostart/xfce4-clipman-plugin-autostart.desktop"
printf '%s\n' 'Clipman autostart has been restored for the next login.'
