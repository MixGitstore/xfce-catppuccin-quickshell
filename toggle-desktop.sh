#!/usr/bin/env bash
set -euo pipefail

desktop_state="$(xprop -root _NET_SHOWING_DESKTOP 2>/dev/null || true)"

if [[ "$desktop_state" == *"= 1" ]]; then
    exec wmctrl -k off
fi

exec wmctrl -k on
