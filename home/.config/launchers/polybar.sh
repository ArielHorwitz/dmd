#! /usr/bin/bash

LOG_FILE=/tmp/polybar.log
iuk log "restarting polybar, logging to '$LOG_FILE'"
polybar-msg cmd quit
sleep 3
polybar --reload main 2>&1 | tee -a $LOG_FILE & disown
sleep 1
SHOW=$([[ -d /mnt/white ]] && echo show || echo hide)
polybar-msg action "#filesystem2.module_$SHOW"

