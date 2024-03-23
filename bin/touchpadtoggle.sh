#!/bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Toggle enable/disable touchpad."
CLI=(
    --prefix "args_"
    -f "on;Enable touchpad"
    -f "off;Disable touchpad"
    -f "status;Print enabled status;;s"
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
    if $(get_status); then
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
    if $(get_status); then
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
