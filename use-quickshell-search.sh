#!/usr/bin/env bash
set -euo pipefail

channel="xfce4-keyboard-shortcuts"
qs_binary=$(command -v qs)
search_command="$qs_binary -c xfce-catppuccin ipc call bar openSearch"

for shortcut in \
    '/commands/custom/<Alt>F2' \
    '/commands/custom/<Alt>F3' \
    '/commands/custom/<Primary>Shift_L' \
    '/commands/custom/<Super>r'
do
    xfconf-query -c "$channel" -p "$shortcut" -s "$search_command"
done

for shortcut in \
    '/commands/custom/<Alt>F2/startup-notify' \
    '/commands/custom/<Alt>F3/startup-notify' \
    '/commands/custom/<Super>r/startup-notify'
do
    xfconf-query -c "$channel" -p "$shortcut" -s false
done

xfce4-appfinder --quit || true
printf '%s\n' 'Quickshell Search has replaced App Finder for the XFCE shortcuts.'
