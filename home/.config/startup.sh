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

log "configuring displays"
displaygeometry -f /etc/iukbtw/devices/monitors
xset -dpms s 7200
xsetroot -solid "#000000"

log "configuring locksreen"
xss-lock --transfer-sleep-lock -- i3lock \
    --nofork --ignore-empty-password --show-failed-attempts --tiling \
    --image "/usr/share/backgrounds/lockscreen.png" &> $LOGDIR/lock.log &

log "running services"
polybar-msg cmd quit
pkill -x iukdaemon
pkill -x kmonad
sleep 1
iukdaemon &> $LOGDIR/iukdaemon.log &
kmdrun &> $LOGDIR/kmd.log &
for MONITOR in $(listmonitors); do
    sleep 0.5
    POLYBAR_MONITOR=$MONITOR polybar --reload main &> $LOGDIR/polybar-main-$MONITOR.log &
done

log "iuk startup complete"

