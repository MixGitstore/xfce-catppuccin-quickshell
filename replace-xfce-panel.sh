#!/usr/bin/env bash
set -euo pipefail

channel=xfce4-session
property=/sessions/Failsafe/Client2_Command
qs_binary=$(command -v qs)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}

# The XFCE system default for this slot is xfce4-panel. Resetting this property
# with restore-xfce-panel.sh therefore provides a simple rollback.
xfconf-query -c "$channel" -p "$property" -r 2>/dev/null || true
xfconf-query -c "$channel" -p "$property" -n -a \
    -t string -s "$qs_binary" \
    -t string --set=-c \
    -t string -s xfce-catppuccin

# Avoid starting a second Quickshell process from XDG autostart.
rm -f "$config_home/autostart/quickshell-catppuccin.desktop"
xfce4-panel --quit 2>/dev/null || true

printf '%s\n' 'Quickshell now occupies the XFCE panel session slot.'
printf '%s\n' 'The XFCE panel package and configuration were kept.'
printf '%s\n' 'Run ./restore-xfce-panel.sh to roll back.'
