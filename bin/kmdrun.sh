#!/bin/bash
set -e

[[ $EUID -eq 0 ]] && exit_error "Do not run $0 as root."

LOG_DIR=/tmp/logs-$USER
CONFIG_DIR=$HOME/.local/share/kmonad
DEVICE_FILE=$HOME/.config/hardware/input
ICON_PATH=$HOME/tux.png
NOTIFY_SYNC_ARG="string:synchronous:volume"

# Find a keyboard device path
all_devices=$(find /dev/input/by-path/ /dev/input/by-id/ -type l)
printcolor -s info "Searching for devices..."
while read my_device; do
    device_path=$(printf "$all_devices" | grep -m 1 $my_device || echo '')
    [[ -z $device_path ]] || break
done <<< $(decomment $DEVICE_FILE)

# Confirm device file found
if [[ -z $device_path ]]; then
    printcolor -s warn "Available devices:" >&2
    printf "\n${all_devices}\n\n" >&2
    printcolor -s warn "Search devices from ${DEVICE_FILE}:"
    cat ${DEVICE_FILE} >&2
    exit_error "Could not find device"
fi
device_name=$(echo $device_path | cut -d'/' -f5)
printcolor -ns info "Found device: "; echo "$device_name"

# Create (combine) new config file
mkdir --parents $CONFIG_DIR
kbd_file=$CONFIG_DIR/$device_name.kbd
printcolor -ns info "KMonad config file: "; echo $kbd_file
[[ ! -e $kbd_file ]] || rm -r $kbd_file
cat $HOME/.config/kmd/* > $kbd_file

# Insert device path into kbd config file
sed -i "s|<KMD_DEVICE_PATH>|${device_path}|" $kbd_file
# Insert start command into kbd config file
start_command="notify-send -h ${NOTIFY_SYNC_ARG} -i ${ICON_PATH} \'Started KMonad\' \'${device_name}\'"
sed -i "s|<KMD_START_CMD>|${start_command}|" $kbd_file

# Kill KMonad
sleep 0.1
pkill -x kmonad || :
setlayer base

# Start KMonad
notify-send -h ${NOTIFY_SYNC_ARG} -i ~/tux.png -u low "Starting KMonad..."
printcolor -s info "Starting KMonad..."
kmonad $kbd_file $@ >${LOG_DIR}/${device_name}.log 2>&1 &
