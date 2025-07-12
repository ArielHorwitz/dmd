#!/bin/bash

keyboard_layout_index=$1
readarray -t device_names < <(hyprctl devices -j | jq -r '.keyboards.[].name' | grep 'kmd')

for device_name in ${device_names[@]}; do
    echo "Switching '$device_name' to layout index $keyboard_layout_index" >&2
    hyprctl switchxkblayout "$device_name" "$keyboard_layout_index"
done
