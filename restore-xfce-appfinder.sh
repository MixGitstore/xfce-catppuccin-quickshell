#!/usr/bin/env bash
set -euo pipefail

channel="xfce4-keyboard-shortcuts"

xfconf-query -c "$channel" -p '/commands/custom/<Alt>F2' \
    -s 'xfce4-appfinder --collapsed'
xfconf-query -c "$channel" -p '/commands/custom/<Alt>F3' \
    -s 'xfce4-appfinder'
xfconf-query -c "$channel" -p '/commands/custom/<Primary>Shift_L' \
    -s '/usr/bin/xfce4-appfinder'
xfconf-query -c "$channel" -p '/commands/custom/<Super>r' \
    -s 'xfce4-appfinder -c'

xfconf-query -c "$channel" -p '/commands/custom/<Alt>F2/startup-notify' -s true
xfconf-query -c "$channel" -p '/commands/custom/<Alt>F3/startup-notify' -s true
xfconf-query -c "$channel" -p '/commands/custom/<Super>r/startup-notify' -s true

printf '%s\n' 'The XFCE App Finder shortcuts have been restored.'
