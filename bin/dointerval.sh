#!/bin/bash

[[ $# -lt 2 ]] && echo "Usage: $0 SLEEP [-c | --clear] COMMAND" >&2 && exit 1
ARGV=( "$@" )

SLEEP_TIME=$1
if [[ $2 = "-c" || $2 = "--clear" ]] ; then
    DO_CLEAR=true
    COMMAND="${ARGV[@]:2}"
else
    DO_CLEAR=false
    COMMAND="${ARGV[@]:1}"
fi

while :; do
    $DO_CLEAR && clear
    eval $COMMAND
    sleep $SLEEP_TIME
done
