#!/bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Toggle enable/disable touchpad."
CLI=(
    --prefix "args_"
    -f "on;Enable touchpad"
    -f "off;Disable touchpad"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# Get touchpad device id
DEVICE=$(xinput --list | grep -i 'touchpad' | cut -d= -f2 | cut -f1 | head -1)

# Determine toggle behavior
if [[ -n $args_on ]]; then
    SETAS="on"
elif [[ -n $args_off ]]; then
    SETAS="off"
else
    ENABLED=$(xinput --list-props $DEVICE | grep -i 'Device Enabled' | cut -d: -f2 | xargs)
    if [[ $ENABLED == "1" ]]; then
        SETAS="off"
    else
        SETAS="on"
    fi
fi

# Set property
if [[ $SETAS == "on" ]]; then
    xinput --set-prop $DEVICE "Device Enabled" 1
elif [[ $SETAS == "off" ]]; then
    xinput --set-prop $DEVICE "Device Enabled" 0
else
    exit_error "Unknown property value: $SETAS"
fi
