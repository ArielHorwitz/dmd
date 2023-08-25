#! /usr/bin/bash

polybar-msg cmd quit

LOGFILE="/tmp/polybar-main.log"

echo "---" | tee -a /tmp/polybar-main.log

for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar --reload main 2>&1 | tee -a $LOGFILE &
done

