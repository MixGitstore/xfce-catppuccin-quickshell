#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
rm -f "$config_home/systemd/user/gvfs-daemon.service.d/no-network.conf"
systemctl --user daemon-reload
systemctl --user restart gvfs-daemon.service

printf '%s\n' 'WSDD/GVFS Network discovery has been restored.'
