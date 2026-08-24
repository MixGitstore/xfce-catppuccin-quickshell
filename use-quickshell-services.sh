#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
mkdir -p "$config_home/autostart"

printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=NetworkManager Applet (replaced by Quickshell)' \
    'Hidden=true' \
    > "$config_home/autostart/nm-applet.desktop"

printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=XFCE Notification Daemon (replaced by Quickshell)' \
    'Hidden=true' \
    > "$config_home/autostart/xfce4-notifyd.desktop"

pkill -x nm-applet 2>/dev/null || true
systemctl --user stop xfce4-notifyd.service 2>/dev/null || \
    pkill -x xfce4-notifyd 2>/dev/null || true

printf '%s\n' 'Network tray and notifications are now managed by Quickshell.'
printf '%s\n' 'No XFCE packages were uninstalled.'
