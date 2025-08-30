#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Get and set volume of default device."
CLI=(
    --prefix "args_"
    -o "volume;Set volume percentage"
    -O "increase;Increase volume percentage;;i"
    -O "decrease;Decrease volume percentage;;d"
    -O "fade-out;Fade out volume over a number of seconds;;O"
    -f "mic;Use source instead of sink"
    -f "mute;Mute device;;m"
    -f "unmute;Unmute device;;u"
    -f "is-mute;Print mute status instead of volume;;M"
    -f "notification;Show notification;;N"
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
tt_out=$(mktemp); tt_err=$(mktemp)
if tigerturtle -WD "$config_default" -p "config__" $config_file -- ${config_keys[@]} >$tt_out 2>$tt_err; then
    eval $(<$tt_out); rm $tt_out; rm $tt_err;
else
    echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1;
fi

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

fade_out() {
    set -e
    local device_type=$1
    local fade_seconds=${2:-5}
    local device_name
    local initial_volume current_volume expected_volume volume_step new_volume
    local steps
    local step_delay=0.1
    device_name=$(print_default_device "$device_type")

    initial_volume=$(print_volume "$device_type")
    expected_volume=$initial_volume
    steps=$(awk "BEGIN {printf \"%.0f\", $fade_seconds / $step_delay}")
    volume_step=$(awk "BEGIN { print int(($initial_volume / ($steps - 1)) + 0.5) }")
    echo "Fading out volume of ${initial_volume}% in $steps steps of ${volume_step}% over ${fade_seconds} seconds" >&2
    [[ $volume_step -gt 0 ]] || exit_error "Cannot fade out with steps of 0%"

    while :; do
        current_volume=$(print_volume "$device_type")
        if [[ current_volume -ne expected_volume ]]; then
            echo "Volume changed externally, stopping fade out" >&2
            return 1
        fi
        new_volume=$(( current_volume - volume_step ))
        [[ $new_volume -gt 0 ]] || new_volume=0
        set_volume "$device_type" "$new_volume"
        [[ $new_volume -gt 0 ]] || break
        expected_volume=$new_volume
        sleep "$step_delay"
    done
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
[[ -z $args_fade_out ]] || fade_out $device_type $args_fade_out

if [[ -n $args_is_mute ]]; then
    print_mute $device_type
elif [[ -n $args_notify_all ]]; then
    notify 'sink'
    sleep 0.1
    notify 'source'
else
    print_volume $device_type
    [[ -z $args_notification ]] || notify $device_type
fi
