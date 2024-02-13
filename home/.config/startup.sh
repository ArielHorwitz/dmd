#! /bin/bash

LOGDIR=/tmp/logs-$USER
[[ ! -d $LOGDIR ]] || rm -rf $LOGDIR
mkdir $LOGDIR

echo -n > $LOGDIR/iuk.log
exec >>$LOGDIR/iuk.log 2>&1

log () {
    timestamp=$(date +"%Y-%m-%d %T")
    echo "$timestamp | $1"
}

log "iuk startup"
localtestinstall -c

log "configuring displays"
displaygeometry --file $HOME/.config/iuk/displays
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

log "running polybar"
polybar-msg cmd quit
for MONITOR in $(displaygeometry --list); do
    sleep 0.5
    POLYBAR_MONITOR=$MONITOR polybar --reload main &> $LOGDIR/polybar-main-$MONITOR.log &
done

log "iuk startup complete"

