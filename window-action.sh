#!/usr/bin/env bash

action="${1:-}"
window_id="${2:-}"

[[ -n "$window_id" ]] || exit 0
command -v wmctrl >/dev/null 2>&1 || exit 0

case "$action" in
    maximize)
        wmctrl -i -r "$window_id" -b toggle,maximized_vert,maximized_horz
        wmctrl -i -a "$window_id"
        ;;
    close)
        wmctrl -i -c "$window_id"
        ;;
esac
