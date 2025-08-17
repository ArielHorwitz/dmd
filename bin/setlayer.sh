#! /bin/bash
set -e

LAYER_FILE=/var/opt/dmd/layer

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Set keyboard state"
CLI=(
    --prefix "args_"
    -O "layout;Set the keyboard layout index"
    -O "led;Set the backlight led state (0 or 1)"
    -O "write;Write text to file"
    -f "read;Read the text from file"
    -O "read-loop;Continuously read the text from file on interval in seconds"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

set_layout() {
    set -e
    local keyboard_layout_index=$1
    local device_names device_name

    readarray -t device_names < <(hyprctl devices -j | jq -r '.keyboards.[].name' | grep 'kmd')
    for device_name in "${device_names[@]}"; do
        echo "Switching '$device_name' to layout index $keyboard_layout_index" >&2
        hyprctl switchxkblayout "$device_name" "$keyboard_layout_index"
    done
}

set_leds() {
    set -e
    local target=$1
    local led
    if [[ $1 -ne 0 ]]; then
        target=100
    fi
    for led in backlight micmute; do
        setled $led -b "$target"
    done
}

write_file() {
    set -e
    printf "%s" "$1" | tee "$LAYER_FILE"
}

if [[ $args_read_loop ]]; then
    touch "$LAYER_FILE"
    while :; do
        cat "$LAYER_FILE"
        echo
        sleep "$args_read_loop"
    done
fi

if [[ $args_read ]]; then
    cat "$LAYER_FILE"
    exit
fi

if [[ $args_layout ]]; then
    set_layout "$args_layout" >/dev/null 2>&1 &
fi

if [[ $args_led ]]; then
    set_leds "$args_led" >/dev/null &
fi

if [[ $args_write ]]; then
    write_file "$args_write" &
fi
