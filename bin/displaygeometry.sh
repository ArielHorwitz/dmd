#! /bin/bash

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="Configure displays"
CLI=(
    -c "displays;Displays from left to right"
    -O "file;Read displays from file;;f"
    -O "primary;Set primary display;;p"
    -f "list;List connected outputs and quit;;l"
    -f "list-all;List all outputs and quit;;L"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $list_all ]] || { xrandr -q | grep "connected" | cut -d' ' -f1 ; exit 0 ; }
[[ -z $list ]] || { xrandr -q | grep " connected" | cut -d' ' -f1 ; exit 0 ; }

xrandr --auto

left=${displays[0]}
for next_display in "${displays[@]}"; do
    echo "$left < $next_display"
    [[ $left = $next_display ]] || xrandr --output $next_display --right-of $left
    left=$next_display
done

[[ -z $primary ]] || xrandr --output $primary --primary

