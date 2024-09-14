#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Get and set volume of default device."
CLI=(
    --prefix "args_"
    -o "volume;Set volume percentage"
    -O "increase;Increase volume percentage;;i"
    -O "decrease;Decrease volume percentage;;d"
    -f "mic;Use source instead of sink"
    -f "mute;Mute device;;m"
    -f "unmute;Unmute device;;u"
    -f "is-mute;Print mute status instead of volume;;M"
    -f "no-notification;Disable notifications;;N"
    -f "notify-all;Show notifications for sink and source"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# CONFIGURATION
config_file=$HOME/.config/${APP_NAME}/config.toml
config_keys=(icons__sink icons__sink_mute icons__source icons__source_mute)
config_default='
[icons]
sink = "/usr/share/icons/dmd/speaker3.svg"
sink_mute = "/usr/share/icons/dmd/speaker0.svg"
source = "/usr/share/icons/dmd/mic1.svg"
source_mute = "/usr/share/icons/dmd/mic0.svg"
'
tt_out=$(mktemp 'tt_out.XXXXXXXXXX'); tt_err=$(mktemp 'tt_err.XXXXXXXXXX'); tigerturtle -WD "$config_default" -p "config__" $config_file -- ${config_keys[@]} >$tt_out 2>$tt_err && { eval $(<$tt_out); rm $tt_out; rm $tt_err; } || { echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1; }

[[ -n $args_mic ]] && device_type="source" || device_type="sink"

print_default_device() {
    set -e
    local device_type=$1
    echo "@DEFAULT_${device_type^^}@"
}

print_volume() {
    set -e
    local device_type=$1
    local device_name=$(print_default_device $device_type)
    local volumes left right
    volumes=$(pactl get-${device_type}-volume ${device_name} | xargs)
    left=$(echo $volumes | awk '{print $5}')
    left="${left%?}"
    right=$(echo $volumes | awk '{print $12}')
    right="${right%?}"
    right=${right:-$left}
    echo $((($left + $right) / 2))
}

set_volume() {
    set -e
    local device_type=$1
    local new_volume=$2
    local device_name=$(print_default_device $device_type)
    pactl set-$1-volume ${device_name} "$new_volume"%
}

set_mute() {
    set -e
    local device_type=$1
    local mute_status=$2
    local device_name=$(print_default_device $device_type)
    pactl "set-${device_type}-mute" ${device_name} ${mute_status}
}

print_mute() {
    set -e
    local device_type=$1
    local device_name=$(print_default_device $device_type)
    [[ $(pactl get-${device_type}-mute ${device_name}) = "Mute: yes" ]] && echo 1 || echo 0
}

notify() {
    local device_type=$1
    local current_volume=$(print_volume $device_type)
    if [[ $(print_mute $device_type) -eq 0 ]]; then
        volume_text="${current_volume}%"
        icon_mute=""
    else
        volume_text="${current_volume}% [MUTED]"
        icon_mute="_mute"
    fi
    hints=(-h int:value:"$current_volume" -h string:synchronous:volume_${device_type})
    description=$([[ $device_type = 'sink' ]] && adevice || adevice --mic)
    icon_name="config__icons__${device_type}${icon_mute}"
    icon=${!icon_name}
    notify-send -u low -t 1500 -i $icon "Volume: ${volume_text}" "${description} (${device_type})" ${hints[@]}
}

[[ -z $args_volume ]] || set_volume $device_type $args_volume
[[ -z $args_increase ]] || set_volume $device_type +$args_increase
[[ -z $args_decrease ]] || set_volume $device_type -$args_decrease

[[ -z $args_mute ]] || set_mute $device_type 1
[[ -z $args_unmute ]] || set_mute $device_type 0

if [[ -n $args_is_mute ]]; then
    print_mute $device_type
elif [[ -n $args_notify_all ]]; then
    notify 'sink'
    sleep 0.1
    notify 'source'
else
    print_volume $device_type
    [[ -n $args_no_notification ]] || notify $device_type
fi
