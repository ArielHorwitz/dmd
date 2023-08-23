#!/bin/bash

# Collect info on touchpad
DEVICE=$(xinput --list | grep -i 'touchpad' | cut -d= -f2 | cut -f1 | head -1)
ENABLED=$(xinput --list-props $DEVICE | grep -i 'Device Enabled' | cut -d: -f2 | xargs)

# Determine toggle behavior
if [[ $ENABLED == "1" ]]; then
    TOGGLE="off"
else
    TOGGLE="on"
fi

# Determine if toggling or using argument
if [[ -z $1 ]]; then
    SETAS=$TOGGLE
else
    SETAS=$1
fi

# Set property
if [[ $SETAS == "on" ]]; then
    xinput --set-prop $DEVICE "Device Enabled" 1
elif [[ $SETAS == "off" ]]; then
    xinput --set-prop $DEVICE "Device Enabled" 0
else
    echo Unknown param: $1
fi
