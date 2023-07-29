#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Must run $0 as root" >&2 && exit 1

[[ -n $1 ]] && LAYER=$1 || LAYER="base"
if [[ -z $(grep -x $LAYER < /etc/opt/iukbtw/layers) ]] ; then
    echo Unknown layer '$LAYER' >&2
    exit 1
fi

# Set layer state
mkdir --parents /var/opt/iukbtw
echo $LAYER | tee /var/opt/iukbtw/layer

# Set display gamma
case $LAYER in
    base ) /opt/iukbtw/bin/gamma;;
    text ) /opt/iukbtw/bin/gamma red;;
esac

# Set keyboard LEDs
GPROFILE="/etc/opt/iukbtw/g610profiles/$LAYER"
echo "Setting g610 profile: $GPROFILE"
[[ -f $GPROFILE ]] && g610-led -p $GPROFILE
while read line ; do
    [[ -z $line ]] && continue
    LED_NAME=$(echo $line | cut -d' ' -f1)
    LED="/sys/class/leds/$(ls -1 /sys/class/leds/ | grep $LED_NAME)"
    BRIGHTNESS=$(echo $line | cut -d' ' -f2)
    if [[ -f $LED/brightness ]]; then
        [[ $BRIGHTNESS -lt 0 ]] && BRIGHTNESS=$(cat $LED/max_brightness)
        printf "Switching $LED $(cat $LED/brightness) > $BRIGHTNESS"
        echo $BRIGHTNESS | tee $LED/brightness
    fi
done < "/etc/opt/iukbtw/leds/$LAYER"
