#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Run a command detached from the terminal with logging"
CLI=(
    --prefix "args_"
    -f "quiet;Discard output instead of logging;;q"
    -O "log-name;Override the log filename base (default: command name)"
    -f "unique-log;Use a unique log filename per invocation;;U"
    -f "truncate-log;Truncate log file before writing;;T"
    -e "command;Command and arguments to run"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

log_name="${args_log_name:-$(basename "${args_command[0]}")}"

if [[ $args_quiet ]]; then
    setsid -f "${args_command[@]}" >/dev/null 2>&1
else
    log_dir="$HOME/.local/state/detach"
    mkdir -p "$log_dir"
    if [[ $args_unique_log ]]; then
        log_file="${log_dir}/${log_name}.$$.log"
    else
        log_file="${log_dir}/${log_name}.log"
    fi
    if [[ $args_truncate_log ]]; then
        setsid -f "${args_command[@]}" >"$log_file" 2>&1
    else
        setsid -f "${args_command[@]}" >>"$log_file" 2>&1
    fi
    echo "$log_file"
fi
