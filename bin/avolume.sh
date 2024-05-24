#! /bin/bash
set -e

APP_NAME=$(basename "$0")
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
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

if [[ -n $args_mic ]]; then
    device_type="source"
else
    device_type="sink"
fi

default_device_name=@DEFAULT_${device_type^^}@

get_volume() {
    set -e
    local volumes left right
    volumes=$(pactl get-${device_type}-volume ${default_device_name} | xargs)
    left=$(echo $volumes | awk '{print $5}')
    left="${left%?}"
    right=$(echo $volumes | awk '{print $12}')
    right="${right%?}"
    echo $((($left + $right) / 2))
}

set_volume() {
    set -e
    pactl set-${device_type}-volume ${default_device_name} "$1"%
}

set_mute() {
    set -e
    pactl "set-${device_type}-mute" ${default_device_name} $1
}

[[ -z $args_volume ]] || set_volume $args_volume
[[ -z $args_increase ]] || set_volume +$args_increase
[[ -z $args_decrease ]] || set_volume -$args_decrease

[[ -z $args_mute ]] || set_mute 1
[[ -z $args_unmute ]] || set_mute 0

if [[ $(pactl get-${device_type}-mute ${default_device_name}) = "Mute: yes" ]]; then
    mute_state=1
else
    mute_state=0
fi

if [[ -n $args_is_mute ]]; then
    echo $mute_state
else
    vol=$(get_volume)
    echo $vol
    if [[ -z $args_no_notification ]]; then
        if [[ $mute_state -eq 0 ]]; then
            volume_text="${vol}%"
        else
            volume_text="${vol}% [MUTED]"
        fi
        hints=(-h int:value:"$vol" -h string:synchronous:volume)
        description=$([[ $device_type = 'sink' ]] && adevice || adevice --mic)
        notify-send -u low -t 1500 "Volume: ${volume_text}" "${description} (${device_type})" ${hints[@]}
    fi
fi
