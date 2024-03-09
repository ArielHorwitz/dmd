#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Get and set volume."
CLI=(
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

if [[ -n $mic ]]; then
    DEVICE="@DEFAULT_SOURCE@"
    COMMAND_DEVICE="source"
else
    DEVICE="@DEFAULT_SINK@"
    COMMAND_DEVICE="sink"
fi

get_volume() {
    volumes=$(pactl "get-$COMMAND_DEVICE-volume" $DEVICE | xargs)
    left=$(echo $volumes | awk '{print $5}')
    left="${left%?}"
    right=$(echo $volumes | awk '{print $12}')
    right="${right%?}"
    echo $((($left + $right) / 2))
}

set_volume() {
    pactl "set-$COMMAND_DEVICE-volume" $DEVICE "$1"%
}

get_mute() {
    if [[ "Mute: yes" = $(pactl "get-$COMMAND_DEVICE-mute" $DEVICE $1) ]]; then
        echo 1
    else
        echo 0
    fi
}

set_mute() {
    pactl "set-$COMMAND_DEVICE-mute" $DEVICE $1
}

[[ -z $volume ]] || set_volume $volume
[[ -z $increase ]] || set_volume +$increase
[[ -z $decrease ]] || set_volume -$decrease

[[ -z $mute ]] || set_mute 1
[[ -z $unmute ]] || set_mute 0

mute=$(get_mute)

if [[ -n $is_mute ]]; then
    echo $mute
else
    vol=$(get_volume)
    echo $vol
    if [[ -z $no_notification ]]; then
        [[ $mute -eq 0 ]] && text="${vol}%" || text="<s>${vol}%</s> <i>(muted)</i>"
        notify-send -t 1500 "Volume: $COMMAND_DEVICE" "$text" -h int:value:"$vol" -h string:synchronous:"volume"
    fi
fi
