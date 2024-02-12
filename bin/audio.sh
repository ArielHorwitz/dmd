#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Get and set volume."
CLI=(
    -o "volume;Set volume percentage"
    -O "increase;Increase volume percentage;;i"
    -O "decrease;Decrease volume percentage;;d"
    -f "mic;Use source instead of sink"
    -f "mute;Mute volume;;m"
    -f "unmute;Unmute volume;;u"
    -f "is-mute;Print mute status instead of volume;;M"
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
NEWLINE='
'
get_volume() {
    volumes=$(pactl "get-$COMMAND_DEVICE-volume" $DEVICE | cut -d"$NEWLINE" -f1)
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

if [[ -n $is_mute ]]; then
    get_mute
else
    get_volume
fi

