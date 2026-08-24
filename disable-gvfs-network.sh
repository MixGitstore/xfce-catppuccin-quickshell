#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
override_dir="$config_home/systemd/user/gvfs-daemon.service.d"
empty_mountable_dir="$data_home/gvfs/mounts-no-network"

mkdir -p "$override_dir" "$empty_mountable_dir"
printf '%s\n' \
    '[Service]' \
    "Environment=\"GVFS_MOUNTABLE_DIR=$empty_mountable_dir\"" \
    > "$override_dir/no-network.conf"

systemctl --user daemon-reload
systemctl --user restart gvfs-daemon.service

printf '%s\n' 'GVFS network discovery has been disabled; local and explicit URI access remain.'
