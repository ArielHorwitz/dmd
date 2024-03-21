#!/bin/bash

APP_NAME=$(basename "$0")
ABOUT="program description"
CLI=(
    --prefix "args_"
    -O "interval;Interval time in seconds;2;i"
    -f "clear;Clear terminal on each interval;;c"
    -f "persistent;Continue even if the command fails;;p"
    -f "time;Print the time on each interval;;t"
    -e "command;Command to run"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -n $args_persistent ]] || set -e

while :; do
    [[ -z $args_clear ]] || clear
    [[ -z $args_time ]] || date
    eval ${args_command[@]}
    sleep $args_interval
done
