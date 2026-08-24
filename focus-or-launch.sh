#!/usr/bin/env bash

window_id="${1:-}"
window_is_active="${2:-0}"
shift 2 || true

# Clicking the active application minimizes it. Otherwise wmctrl asks XFWM to
# switch workspace if needed, restore, raise and focus the existing window. If
# it disappeared between detection and click, launch a new instance instead.
if [[ -n "$window_id" ]] && command -v wmctrl >/dev/null 2>&1; then
    window_state="$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null)"

    if [[ "$window_state" == *"_NET_WM_STATE_HIDDEN"* ]]; then
        wmctrl -i -a "$window_id" && exit 0
    elif [[ "$window_is_active" == "1" ]]; then
        wmctrl -i -r "$window_id" -b add,hidden && exit 0
    elif wmctrl -i -a "$window_id"; then
        exit 0
    fi
fi

if (( $# > 0 )); then
    exec "$@"
fi
