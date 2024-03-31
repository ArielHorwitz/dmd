#! /bin/bash

set -e

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="Control the mouse"
CLI=(
    -O "click;Click mouse button by number;;C"
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

if [[ -n "$center$top$bottom$left$right" ]]; then
    mx=$(( X + WIDTH / 2 ))
    [[ -z $right ]] || mx=$(( X + WIDTH - edge_offset ))
    [[ -z $left ]] || mx=$(( X + edge_offset ))

    my=$(( Y + HEIGHT / 2 ))
    [[ -z $bottom ]] || my=$(( Y + HEIGHT - edge_offset ))
    [[ -z $top ]] || my=$(( Y + edge_offset ))

    xdotool mousemove $mx $my
fi

[[ -z $click ]] || xdotool click $click

