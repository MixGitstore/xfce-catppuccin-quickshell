#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
rm -f \
    "$config_home/autostart/nm-applet.desktop" \
    "$config_home/autostart/xfce4-notifyd.desktop"

systemctl --user start xfce4-notifyd.service 2>/dev/null || \
    /usr/lib64/xfce4/notifyd/xfce4-notifyd >/dev/null 2>&1 &

if ! pgrep -x nm-applet >/dev/null 2>&1; then
    nm-applet >/dev/null 2>&1 &
fi

printf '%s\n' 'nm-applet and xfce4-notifyd have been restored.'
