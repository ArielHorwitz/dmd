#! /bin/bash

LOGDIR=/tmp/logs-$USER
[[ -d $LOGDIR ]] || mkdir $LOGDIR

echo -n > $LOGDIR/polybar.log
echo -n > $LOGDIR/iukdaemon.log
echo -n > $LOGDIR/kmd.log
echo -n > $LOGDIR/lock.log
echo -n > $LOGDIR/iuk.log
exec >>$LOGDIR/iuk.log 2>&1

log () {
    timestamp=$(date +"%Y-%m-%d %T")
    echo "$timestamp | $1"
}

log "iuk startup"

log "running services"
polybar-msg cmd quit
pkill -x iukdaemon
pkill -x kmonad
sleep 1
POLYBAR_MONITOR="DP-2" polybar --reload main &> $LOGDIR/polybar.log &
iukdaemon &> $LOGDIR/iukdaemon.log &
kmdrun &> $LOGDIR/kmd.log &

log "configuring displays"
displaygeometry -f /etc/iukbtw/devices/monitors
xset -dpms s 7200
~/.fehbg

log "configuring locksreen"
xss-lock --transfer-sleep-lock -- i3lock \
    --nofork --ignore-empty-password --show-failed-attempts --tiling \
    --image "/usr/share/backgrounds/lockscreen.png" &> $LOGDIR/lock.log &

log "iuk startup complete"

