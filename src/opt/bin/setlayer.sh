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

# Set keyboard LEDs
GPROFILE="/etc/opt/iukbtw/g610profiles/$LAYER"
[[ -f $GPROFILE ]] && g610-led -p $GPROFILE
while read line ; do
    [[ -z $line ]] && continue
    LED="/sys/class/leds/$(ls -1 /sys/class/leds/ | grep $line)"
    if [[ -f $LED/brightness ]]; then
        [[ $LAYER = "text" ]] && BRIGHTNESS=$(cat $LED/max_brightness) || BRIGHTNESS=0
        printf "Switching $LED $(cat $LED/brightness) > "
        echo $BRIGHTNESS | tee $LED/brightness
    fi
done < /etc/opt/iukbtw/leds

# Play audio
case $LAYER in
    base)       aplay /opt/iukbtw/audio/base.wav ;;
    text)       aplay /opt/iukbtw/audio/text.wav ;;
    *)          echo "Unknown layer '$LAYER'" >&2 ;;
esac
