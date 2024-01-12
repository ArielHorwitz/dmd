#! /bin/bash

SLEEPTIME=0.5

iuk log --reset
iuk log "iuk startup"


iuk log "configuring displays"
displaygeometry -f /etc/iukbtw/devices/monitors
xset -dpms s 7200
~/.fehbg


iuk log "launching polybar, logging to /tmp/polybar.log"
POLYBAR_MONITOR="HDMI-1" polybar --reload main &> /tmp/polybar.log & disown


iuk log "layout sys"
i3-msg "workspace d1"
pkill -x iukdaemon
pkill -x kmonad
sleep 1
alacritty --title "iukdaemon" --command iukdaemon & disown
alacritty --title "kmonad" --command kmdrun & disown


iuk log "iuk startup complete"

