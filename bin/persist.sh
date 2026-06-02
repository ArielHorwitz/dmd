#! /bin/bash

APP_NAME=$(basename "${0%.*}")
ABOUT="Run a command in a restart loop"
CLI=(
    --prefix "args_"
    -O "delay;Delay in seconds before restarting;3"
    -C "command;Command to run"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

while true; do
    "${args_command[@]}"
    exit_code=$?
    printcolor -nf cyan "$(date '+%Y-%m-%d %H:%M:%S') "
    printcolor -s warn "Command exited ($exit_code). Restarting in ${args_delay}s..."
    sleep "$args_delay"
done
