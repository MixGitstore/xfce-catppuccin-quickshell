#!/usr/bin/env bash

# Remove the user override so XFCE inherits its original system session entry:
# /sessions/Failsafe/Client2_Command = [xfce4-panel]
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
xfconf-query \
    --channel xfce4-session \
    --property /sessions/Failsafe/Client2_Command \
    --reset

rm -f "$config_home/autostart/quickshell-catppuccin.desktop"

if ! pgrep -x xfce4-panel >/dev/null 2>&1; then
    xfce4-panel >/dev/null 2>&1 &
fi

printf '%s\n' 'The original XFCE panel startup has been restored.'
