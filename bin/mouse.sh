#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Control the mouse"
CLI=(
    --prefix "args_"
    -o "click;Click mouse button by number"
    -o "count;Number of clicks;1"
    -O "delay;Delay between clicks in ms;0"
    -O "edge-offset;Pixel offset when moving mouse to edge;1;O"
    -f "center;Move mouse to window center;;c"
    -f "top;Move mouse to window top edge;;t"
    -f "bottom;Move mouse to window bottom edge;;b"
    -f "left;Move mouse to window left edge;;l"
    -f "right;Move mouse to window right edge;;r"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

eval $(xdotool getactivewindow getwindowgeometry --shell)

if [[ -n "$args_center$args_top$args_bottom$args_left$args_right" ]]; then
    mx=$(( X + WIDTH / 2 ))
    [[ -z $args_right ]] || mx=$(( X + WIDTH - args_edge_offset ))
    [[ -z $args_left ]] || mx=$(( X + args_edge_offset ))

    my=$(( Y + HEIGHT / 2 ))
    [[ -z $args_bottom ]] || my=$(( Y + HEIGHT - args_edge_offset ))
    [[ -z $args_top ]] || my=$(( Y + args_edge_offset ))

    xdotool mousemove $mx $my
fi

[[ -z $args_click ]] || xdotool click --delay $args_delay --repeat $args_count $args_click
