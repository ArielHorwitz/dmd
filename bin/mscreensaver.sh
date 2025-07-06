#! /bin/bash

COLORS=(green red blue yellow cyan magenta)

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Run a matrix-style screensaver as a workaround for wayland not having screensavers."
CLI=(
    --prefix "args_"
    -o "color;Choose color instead of random (overrides --multi-color)"
    -O "scroll-speed;Scrolling animation speed;4;s"
    -f "multi-color;Use different color for each screen"
    -f "lock;Lock after screensaver;;L"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

monitors=($(hyprctl monitors -j | jq -r '.[].name'))
colors=($(printf "%s\n" "${COLORS[@]}" | shuf))

if [[ $args_color ]]; then
    args_multi_color=
    colors=($args_color)
fi

pids=()
for i in ${!monitors[@]}; do
    monitor=${monitors[i]}
    if [[ $args_multi_color ]]; then
        color=${colors[i]}
    else
        color=${colors[0]}
    fi
    echo "Monitor: $monitor [color: $color]" >&2
    hyprctl dispatch focusmonitor "$monitor"
    command=(r-matrix --colour $color --update $args_scroll_speed -s)
    alacritty --class "mscreensaver__make_window_float_" --command ${command[@]} &
    pid=$!
    echo "PID: $pid"
    pids+=("$pid")
    sleep 0.3
    ps "$pid" >/dev/null || exit_error "r-matrix command failed"
    hyprctl dispatch fullscreen 2
done

wait_any_pid() {
    while :; do
        sleep 0.05
        for pid in "${pids[@]}"; do
            if ! ps "$pid" >/dev/null ; then
                return 0
            fi
            client_info=$(hyprctl clients -j | jq -r --arg pid "$pid" '.[] | select(.pid == ($pid|tonumber))')
            if [[ $(echo "$client_info" | jq -r '.fullscreen') -ne 2 ]] \
                || [[ $(echo "$client_info" | jq -r '.hidden') -ne 0 ]]; then
                return 0
            fi
        done
    done
}

wait_any_pid

if [[ $args_lock ]]; then
    echo "Locking"
    nohup hyprlock
fi

echo "Closing all screensavers"
killall r-matrix
