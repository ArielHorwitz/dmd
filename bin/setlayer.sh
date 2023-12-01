#!/bin/bash

setlayer() {
    polybar-msg action kmd hook $1
    gamma $2
}

case $1 in
    base ) iuk log "$(setlayer 0)" ;;
    text ) iuk log "$(setlayer 1 cyan)" ;;
    *    ) iuk log "No such layer $1" ;;
esac
