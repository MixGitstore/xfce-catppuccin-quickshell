#!/usr/bin/env bash

# Emit client windows in EWMH stacking order. This runs only when XFWM reports
# that the client list changed, so there is no periodic polling.
client_list="$(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null)" || exit 0
client_list="${client_list#*#}"
client_list="${client_list//,/ }"

for qs_window_id in $client_list; do
    window_data="$(xprop -id "$qs_window_id" \
        WM_CLASS _NET_WM_NAME _NET_WM_STATE _NET_WM_WINDOW_TYPE 2>/dev/null)" || continue
    class_data="${window_data%%$'\n'*}"
    remaining_data="${window_data#*$'\n'}"
    title_data="${remaining_data%%$'\n'*}"
    window_title="${title_data#*= }"
    window_title="${window_title#\"}"
    window_title="${window_title%\"}"
    window_title="${window_title//$'\t'/ }"
    window_title="${window_title//$'\n'/ }"
    skip_taskbar=0

    if [[ "$window_data" == *"_NET_WM_STATE_SKIP_TASKBAR"* \
        || "$window_data" == *"_NET_WM_WINDOW_TYPE_DOCK"* \
        || "$window_data" == *"_NET_WM_WINDOW_TYPE_DESKTOP"* ]]; then
        skip_taskbar=1
    fi

    if [[ "$class_data" == WM_CLASS* && "$class_data" != *"not found"* ]]; then
        printf '%s\t%s\t%s\t%s\n' \
            "$qs_window_id" "$skip_taskbar" "$window_title" "$class_data"
    fi
done
