#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Control the mouse.

Order of operations:
- Move to window edge
- Move by pixels
- Click buttons

Available buttons:
- left (l)
- right (r)
- middle (m)
- back (b)
- forward (f)
- wheel-up (wu)
- wheel-down (wd)
- wheel-left (wl)
- wheel-right (wr)"
CLI=(
    --prefix "args_"
    -c "clicks;Click mouse buttons in sequence (see --help)"
    -O "repeat;Repeat clicks of mouse button sequence;1;r"
    -O "delay;Delay between clicks in seconds;0.02"
    -O "up;Move the mouse up by pixels;0;U"
    -O "down;Move the mouse down by pixels;0;D"
    -O "left;Move the mouse left by pixels;0;L"
    -O "right;Move the mouse right by pixels;0;R"
    -O "window-edge;Move mouse to window edge (any or all of: c, t, b, l, r);;E"
    -O "edge-offset;Pixel offset when moving mouse to edge;1;O"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

if [[ -n $args_window_edge ]]; then
    window_info=$(hyprctl activewindow -j)
    window_x=$(echo "$window_info" | jq -r '.at.[0]')
    window_y=$(echo "$window_info" | jq -r '.at.[1]')
    window_w=$(echo "$window_info" | jq -r '.size.[0]')
    window_h=$(echo "$window_info" | jq -r '.size.[1]')
    mouse_x=$(( window_x + window_w / 2 ))
    mouse_y=$(( window_y + window_h / 2 ))
    while IFS='' read -rn1 edge; do
        case $edge in
            r )  mouse_x=$(( window_x + window_w - args_edge_offset )) ;;
            l )  mouse_x=$(( window_x + args_edge_offset )) ;;
            b )  mouse_y=$(( window_y + window_h - args_edge_offset )) ;;
            t )  mouse_y=$(( window_y + args_edge_offset )) ;;
        esac
    done <<< "$args_window_edge"
    ydotool mousemove --absolute "$mouse_x" "$mouse_y"
fi

mouse_x=$(( args_right - args_left ))
mouse_y=$(( args_down - args_up ))
ydotool mousemove -- "$mouse_x" "$mouse_y"

for ((i=0; i<args_repeat; i++)); do
    for button in "${args_clicks[@]}"; do
        ydt_args=()
        case $button in
            l | left ) ydt_args=(click "0xC0") ;;
            r | right ) ydt_args=(click "0xC1") ;;
            m | middle ) ydt_args=(click "0xC2") ;;
            b | forward ) ydt_args=(click "0xC5") ;;
            f | back ) ydt_args=(click "0xC6") ;;
            wu | wheel-up ) ydt_args=(mousemove --wheel -- "0" "1") ;;
            wd | wheel-down ) ydt_args=(mousemove --wheel -- "0" "-1") ;;
            wl | wheel-left ) ydt_args=(mousemove --wheel -- "1" "0") ;;
            wr | wheel-right ) ydt_args=(mousemove --wheel -- "-1" "0") ;;
            * ) exit_error "Unknown button: $button" ;;
        esac
        ydotool "${ydt_args[@]}"
        sleep "$args_delay"
    done
done
