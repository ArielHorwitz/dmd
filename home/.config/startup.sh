#! /bin/bash

DISPLAYS_FILE=$HOME/.config/hardware/displays

LOGDIR=/tmp/logs-$USER
LOGFILE=$LOGDIR/startup.log
echo "Startup script logging to: $LOGFILE"
[[ ! -d $LOGDIR ]] || rm -rf $LOGDIR
mkdir $LOGDIR
echo -n > $LOGFILE
exec >>$LOGFILE 2>&1

log () {
    timestamp=$(date +"%Y-%m-%d %T")
    echo "$timestamp | $1"
}

run_polybar() {
    local display=$1
    local barname=$2
    log "running polybar '$barname' for: '$display'"
    sleep 0.5
    POLYBAR_MONITOR=$display polybar --reload $barname &> $LOGDIR/polybar-$barname-$display.log &
}

log "iuk startup"
localtestinstall -c

log "configuring displays"
xgeometry --file $DISPLAYS_FILE
xset -dpms s 7200
xsetroot -solid "#000000"

log "configuring locksreen"
lockscreen_image="/usr/share/backgrounds/lockscreen.png"
i3lock_args=(
    "--nofork"
    "--ignore-empty-password"
    "--show-failed-attempts"
    "--tiling"
    "--image" "$lockscreen_image"
)
xss-lock --transfer-sleep-lock -- i3lock ${i3lock_args[@]} &> $LOGDIR/lock.log &

log "running kmonad"
kmdrun &> $LOGDIR/kmd.log &

log "closing polybar"
polybar-msg cmd quit
mapfile -t displays < $DISPLAYS_FILE
run_polybar ${displays[1]} main

log "toggling touchpad"
touchpadtoggle --off

log "iuk startup complete"
