#!/bin/bash

[[ $EUID -eq 0 ]] && echo "Do not run $0 as root." >&2 && exit 1

# Find a keyboard device path
device_file=/etc/iukbtw/devices/input
all_device_files="$(find /dev/input/by-path/ /dev/input/by-id/)"
while read my_device; do
    my_device="$(echo $my_device | cut -d'#' -f1 | xargs)"
    [[ -z $my_device ]] && continue
    echo "Searching for device: $my_device"
    device=$(printf "$all_device_files" | grep -m 1 $my_device)
    [[ -n $device ]] && break
done < $device_file

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
cat /etc/iukbtw/kmd/* > $kbd_file
# Insert device file path into kbd config file

sedcmd=("\
s|DEVICE_FILE_PATH|$device|;\
s|<KMD_MONITOR_LEFT>|HDMI-1|;\
s|<KMD_MONITOR_CENTER>|HDMI-1|;\
s|<KMD_MONITOR_RIGHT>|DP-2|;\
")
sed -i "${sedcmd[@]}" $kbd_file

# Kill KMonad
sleep 0.1
pkill -x kmonad
setlayer base

# Start KMonad
notify-send -u critical -t 3000 -i ~/tux.png "Starting KMonad" "$(echo $device | cut -d'/' -f5)"
echo "Starting KMonad with $kbd_file"
kmonad $kbd_file $@
