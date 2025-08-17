#! /bin/bash
set -e

LEDS_DIR="/sys/class/leds"

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Set brightness of an LED.

Requires write permission to the brightness control files under $LEDS_DIR."
CLI=(
    --prefix "args_"
    -o "led;Name of LED (leave blank to list available LEDs)"
    -O "brightness;New brightness in percent;;b"
    -f "toggle;Toggle led;;t"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
# exit
eval "$CLI" || exit 1

if [[ -z $args_led ]]; then
    ls -1 $LEDS_DIR
    exit
fi

led_name=$(ls -1 $LEDS_DIR | grep "$args_led" | head -n1)
led_path="$LEDS_DIR/$led_name"
[[ $led_name && -d $led_path ]] || exit_error "failed to find led named $args_led"

current_brightness=$(cat "$led_path/brightness")
max_brightness=$(cat "$led_path/max_brightness")

echo "$led_path"
echo "Brightness: $current_brightness [max: $max_brightness]"

if [[ $args_brightness ]]; then
    target_float=$(awk "BEGIN {print $max_brightness * ($args_brightness / 100)}")
    target=$(printf "%.0f" "$target_float")
elif [[ $args_toggle ]]; then
    if [[ $current_brightness == "$max_brightness" ]]; then
        target=0
    else
        target=$max_brightness
    fi
else
    exit
fi

echo "Setting to: $target"

echo "$target" | tee "$led_path/brightness" > /dev/null
