#!/bin/bash
set -e

DEVICE_FILE=$HOME/.config/iuk/audio/headphones

all_devices=`pactl list short`
while read selected_device; do
    echo "Searching for device: $selected_device"
    device=$(echo $all_devices | grep -m 1 $selected_device || echo '')
    [[ -n $device ]] && break
done <<< `decomment $DEVICE_FILE`

echo "Selected device: $selected_device"
pactl set-default-sink $selected_device

