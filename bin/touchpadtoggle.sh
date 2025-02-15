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

# Get touchpad device id
DEVICE=$(xinput --list | grep -i 'touchpad' | cut -d= -f2 | cut -f1 | head -1)

get_status() {
    ENABLED=$(xinput --list-props $DEVICE | grep -i 'Device Enabled' | cut -d: -f2 | xargs)
    [[ $ENABLED == "1" ]] && return 0 || return 1
}

if [[ $args_status ]]; then
    if get_status; then
        echo "Touchpad enabled"
        exit 0
    else
        echo "Touchpad disabled"
        exit 1
    fi
fi

# Determine toggle behavior
if [[ -n $args_on ]]; then
    SETAS="on"
elif [[ -n $args_off ]]; then
    SETAS="off"
else
    if get_status; then
        SETAS="off"
    else
        SETAS="on"
    fi
fi

notification_args=(-u low -t 1500 -h string:synchronous:touchpadtoggle)

# Set property
if [[ $SETAS == "on" ]]; then
    xinput --set-prop "$DEVICE" "Device Enabled" 1
    echo "Enabled touchpad"
    [[ $args_no_notification ]] || notify-send "Enabled touchpad" "${notification_args[@]}"
elif [[ $SETAS == "off" ]]; then
    xinput --set-prop "$DEVICE" "Device Enabled" 0
    echo "Disabled touchpad"
    [[ $args_no_notification ]] || notify-send "Disabled touchpad" "${notification_args[@]}"
else
    exit_error "Unknown property value: $SETAS"
fi
