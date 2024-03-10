#!/bin/bash

[[ $EUID -eq 0 ]] && echo "Do not run $0 as root." >&2 && exit 1

# Find displays
DISPLAYS_FILE=$HOME/.config/hardware/displays
mapfile -t displays < $DISPLAYS_FILE

# Find a keyboard device path
device_file=$HOME/.config/hardware/input
all_device_files=`find /dev/input/by-path/ /dev/input/by-id/ -type l`
while read my_device; do
    echo "Searching for device: $my_device"
    device=$(printf "$all_device_files" | grep -m 1 $my_device || echo '')
    [[ -n $device ]] && break
done <<< `decomment $device_file`

# Confirm device file found
if [[ -z $device ]]; then
    printf "\n\nAvailable devices:\n$all_device_files\n\n" >&2
    printf "Could not find devices from $device_file:\n$(cat $device_file)\n" >&2
    exit 1
fi
echo "kmd device: $device"

# Create (combine) new config file
LOCAL_CONFIG=$HOME/.local/share/kmonad
mkdir --parents $LOCAL_CONFIG
kbd_file="$LOCAL_CONFIG/tmpconfig.kbd"
cat $HOME/.config/kmd/* > $kbd_file

# Insert device path into kbd config file
sed -i "s|<KMD_DEVICE_PATH>|$device|" $kbd_file

# Kill KMonad
sleep 0.1
pkill -x kmonad
setlayer base

# Start KMonad
notify-send -i ~/tux.png "Starting KMonad" "$(echo $device | cut -d'/' -f5)"
echo "Starting KMonad with $kbd_file"
kmonad $kbd_file $@
