#!/bin/bash

DEVICE_FILE=$HOME/.config/iuk/hardware/headphones

all_devices=`pactl list short`
while read selected_device; do
    selected_device="$(echo $selected_device | cut -d'#' -f1 | xargs)"
    [[ -z $selected_device ]] && continue
    echo "Searching for device: $selected_device"
    device=$(echo $all_devices | grep -m 1 $selected_device)
    [[ -n $device ]] && break
done < $DEVICE_FILE

echo "Selected device: $selected_device"
pactl set-default-sink $selected_device

