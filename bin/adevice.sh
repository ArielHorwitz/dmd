#! /bin/bash
set -e

HARDWARE_DIR=$HOME/.config/adevice

APP_NAME=$(basename "$0")
ABOUT="Get and set default audio device.

# Device Classes
When using the '--class' flag, the device is not named directly. A device
\"class\" is name which corresponds to a file of that name within the
${HARDWARE_DIR} directory.

These files contain a list of device names by order of priority."
CLI=(
    --prefix "args_"
    -o "device;Set default device by name (or class name with --class)"
    -f "class;Name a device by class instead of name;;c"
    -f "mic;Use source instead of sink;;m"
    -f "list;List devices or classes;;l"
    -f "no-notification;Disable notifications;;N"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


if [[ -n $args_mic ]]; then
    device_type="source"
else
    device_type="sink"
fi


find_device() {
    set -e
    local class=$1
    local file="${HARDWARE_DIR}/${device_type}s/${class}"
    [[ -f $file ]] || exit_error "${file} does not exist"
    local device device_exists all_devices
    all_devices=$(pactl list short)
    for device in $(decomment "$file"); do
        if [[ $(printf "$all_devices" | grep -m 1 $device) ]]; then
            echo $device
            return 0
        fi
    done
    exit_error "Failed to find conneceted device from ${file}"
}

get_description() {
    set -e
    local device_name="$1"
    jq_script=".[] | select(.name == \"${device_name}\") | .properties[\"device.description\"]"
    pactl --format=json list ${device_type}s | jq -r "${jq_script}"
}

if [[ -n $args_list ]]; then
    # List devices
    if [[ $device_type = 'source' ]]; then
        pactl list short sources | awk '{print $0 $1}'
    elif [[ $device_type = 'sink' ]]; then
        pactl list short sinks | awk '{print $0 $1}'
    else
        exit_error "Unknown device type ${device_type}"
    fi
    exit 0
elif [[ -n $args_device ]]; then
    # Set default device
    if [[ -n $args_class ]]; then
        device_name=$(find_device "${args_device}")
    else
        device_name=$args_device
    fi
    pactl set-default-${device_type} ${device_name}

    if [[ -z $no_notification ]]; then
        [[ $device_type = 'sink' ]] && avolume || avolume --mic
    fi
else
    # Print default device description
    device_name=$(pactl get-default-${device_type})
    get_description $device_name
    exit 0
fi
