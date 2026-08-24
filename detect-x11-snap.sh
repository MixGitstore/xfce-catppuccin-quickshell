#!/usr/bin/env bash

# Print 1 when the requested X11 client matches one of XFWM's half/quarter
# tiling geometries. This is invoked only after a frame/state event, not polled.
target_id=${1:-}
if [[ ! $target_id =~ ^0x[0-9a-fA-F]+$ ]] || (( target_id == 0 )); then
    printf '0\n'
    exit 0
fi

window_x=0
window_y=0
window_width=0
window_height=0
window_found=0
target_number=$((target_id))

while read -r listed_id _ listed_x listed_y listed_width listed_height _; do
    if [[ $listed_id =~ ^0x[0-9a-fA-F]+$ ]] \
            && (( listed_id == target_number )); then
        window_x=$listed_x
        window_y=$listed_y
        window_width=$listed_width
        window_height=$listed_height
        window_found=1
        break
    fi
done < <(wmctrl -lG 2>/dev/null)

if (( ! window_found || window_width <= 0 || window_height <= 0 )); then
    printf '0\n'
    exit 0
fi

# wmctrl reports the client geometry. Expand it to the decorated XFWM frame.
frame_left=0
frame_right=0
frame_top=0
frame_bottom=0
frame_record=$(xprop -id "$target_id" _NET_FRAME_EXTENTS 2>/dev/null)
frame_values=${frame_record#*=}
frame_values=${frame_values//,/ }
read -r frame_left frame_right frame_top frame_bottom <<< "$frame_values"
frame_left=${frame_left:-0}
frame_right=${frame_right:-0}
frame_top=${frame_top:-0}
frame_bottom=${frame_bottom:-0}

window_x=$((window_x - frame_left))
window_y=$((window_y - frame_top))
window_width=$((window_width + frame_left + frame_right))
window_height=$((window_height + frame_top + frame_bottom))

work_x=0
work_y=0
work_width=0
work_height=0
while IFS= read -r desktop_record; do
    if [[ $desktop_record == *"*"* \
            && $desktop_record =~ WA:[[:space:]]*(-?[0-9]+),(-?[0-9]+)[[:space:]]+([0-9]+)x([0-9]+) ]]; then
        work_x=${BASH_REMATCH[1]}
        work_y=${BASH_REMATCH[2]}
        work_width=${BASH_REMATCH[3]}
        work_height=${BASH_REMATCH[4]}
        break
    fi
done < <(wmctrl -d 2>/dev/null)

if (( work_width <= 0 || work_height <= 0 )); then
    printf '0\n'
    exit 0
fi

absolute_difference() {
    local difference=$(( $1 - $2 ))
    (( difference < 0 )) && difference=$((-difference))
    printf '%s' "$difference"
}

# XFWM respects size increments, decorations and reserved panel space. A small
# tolerance keeps terminals and CSD windows detectable without classifying an
# ordinary edge-aligned restored window as tiled.
size_tolerance=52
edge_tolerance=52

left_difference=$(absolute_difference "$window_x" "$work_x")
right_difference=$(absolute_difference \
    "$((window_x + window_width))" "$((work_x + work_width))")
top_difference=$(absolute_difference "$window_y" "$work_y")
bottom_difference=$(absolute_difference \
    "$((window_y + window_height))" "$((work_y + work_height))")
half_width_difference=$(absolute_difference "$((window_width * 2))" "$work_width")
half_height_difference=$(absolute_difference "$((window_height * 2))" "$work_height")
full_width_difference=$(absolute_difference "$window_width" "$work_width")
full_height_difference=$(absolute_difference "$window_height" "$work_height")

at_horizontal_edge=0
at_vertical_edge=0
(( left_difference <= edge_tolerance || right_difference <= edge_tolerance )) \
    && at_horizontal_edge=1
(( top_difference <= edge_tolerance || bottom_difference <= edge_tolerance )) \
    && at_vertical_edge=1

half_width=0
half_height=0
full_width=0
full_height=0
(( half_width_difference <= size_tolerance )) && half_width=1
(( half_height_difference <= size_tolerance )) && half_height=1
(( full_width_difference <= size_tolerance )) && full_width=1
(( full_height_difference <= size_tolerance )) && full_height=1

if (( (half_width && full_height && at_horizontal_edge && at_vertical_edge)
        || (full_width && half_height && at_horizontal_edge && at_vertical_edge)
        || (half_width && half_height && at_horizontal_edge && at_vertical_edge) )); then
    printf '1\n'
else
    printf '0\n'
fi
