#!/bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Toggle enable/disable touchpad."
CLI=(
    --prefix "args_"
    -f "on;Enable touchpad"
    -f "off;Disable touchpad"
    -f "no-notification;Disable notification of enabled status;;n"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


status_file=$XDG_RUNTIME_DIR/touchpad.status
all_touchpads=$(hyprctl devices -j | jq -r '.mice.[].name' | grep 'touchpad')

[[ -f "$status_file" ]] || printf "true" >"$status_file"

get_status() {
    if [[ $(cat "$status_file") = 'false' ]]; then
        return 1
    else
        return 0
    fi
}

# Determine toggle behavior
if [[ -n $args_on ]]; then
    setas="true"
elif [[ -n $args_off ]]; then
    setas="false"
else
    if get_status; then
        setas="false"
    else
        setas="true"
    fi
fi

if [[ $setas = "true" ]]; then
    notification_title="Enabled touchpad"
else
    notification_title="Disabled touchpad"
fi

notification_args=(-u low -t 1500 -h string:synchronous:touchpadtoggle)

# Set status
for device in $all_touchpads; do
    hyprctl -r -- keyword device["$device"]:enabled "$setas" >/dev/null
done
# Save status to file
printf "%s" "$setas" >"$status_file"
# Status notification
echo "$notification_title"
[[ $args_no_notification ]] || notify-send "$notification_title" "${notification_args[@]}"
