#! /bin/bash

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="Configure displays"
CLI=(
    --prefix "args_"
    -c "displays;Displays from left to right"
    -O "primary;Set primary display;;p"
    -f "disable;Disable all other outputs;;d"
    -f "list;List connected outputs and quit;;l"
    -f "list-all;List all outputs and quit;;L"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $args_list_all ]] || { xrandr -q | grep "connected" | sort ; exit 0 ; }
[[ -z $args_list ]] || { xrandr -q | grep " connected" | sort ; exit 0 ; }


if [[ -n $args_displays ]]; then
    # enable/disable displays
    if [[ $args_disable ]]; then
        # disable all displays
        while read -r output; do
            echo "disabling $output" >&2
            xrandr --output "$output" --off
        done < <(xrandr -q | grep " connected" | awk '{print $1}')
        # enable configured displays
        for output in "${args_displays[@]}"; do
            echo "enabling $output" >&2
            xrandr --output "$output" --auto
        done
    else
        xrandr --auto
    fi
    # arrange displays
    left=${args_displays[0]}
    echo -n "$left"
    for next_display in "${args_displays[@]:1}"; do
        echo -n " | $next_display"
        [[ $left = $next_display ]] || xrandr --output $next_display --right-of $left
        left=$next_display
    done
    echo
fi

[[ -z $args_primary ]] || xrandr --output $args_primary --primary
