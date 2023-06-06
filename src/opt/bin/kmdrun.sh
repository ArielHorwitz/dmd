#!/bin/bash

[[ $EUID -eq 0 ]] && echo "Do not run $0 as root." && exit 1

# Kill KMonad and reset state file
sleep 0.2s
pkill -x kmonad
sleep 0.2s
sudo /opt/iukbtw/bin/setlayer base

# Find a keyboard device path
all_device_files="$(find /dev/input/by-path/ /dev/input/by-id/)"
while read my_device; do
    my_device="$(echo $my_device | cut -d'#' -f1 | xargs)"
    [[ -z $my_device ]] && continue
    echo "Searching for device: $my_device"
    device=$(printf "$all_device_files" | grep -m 1 $my_device)
    [[ -n $device ]] && break
done < /etc/opt/iukbtw/devices

# Confirm device file found
echo "kmd device: $device"
if [[ -z $device ]]; then
    my_devices=$(cat /etc/opt/iukbtw/devices)
    printf "\n\nAvailable devices:\n$all_device_files\n\n" >&2
    printf "Could not find devices from /etc/opt/iukbtw/devices:\n$my_devices\n" >&2
    exit 1
fi

set -e

# Create new config file from template
mkdir --parents "$HOME/.local/share/kmonad"
kbd_file="$HOME/.local/share/kmonad/tmpconfig.kbd"
cp -f "/etc/opt/iukbtw/kmonad/template.hs" $kbd_file
# Insert device file path into kbd config file
sed -i "s;DEVICE_FILE_PATH;$device;" $kbd_file

# Start KMonad
notify-send -u critical -t 3000 -i ~/tux.png "Starting KMonad" "$(echo $device | cut -d'/' -f5)"
echo Starting KMonad with $kbd_file
kmonad $kbd_file $@
