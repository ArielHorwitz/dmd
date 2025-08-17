#!/bin/bash
set -e

DEFAULT_SEPARATOR=" :: "


# CLI
APP_NAME=$(basename "$0")
ABOUT="Execute commands from file via rofi."
CLI=(
    --prefix "args_"
    -o "selection;Selected line to execute (provided by rofi)"
    -O "file;File containing text and commands;;f"
    -O "unsafe-file;File that is writable by non-root"
    -O "separator;Separator between text and command;$DEFAULT_SEPARATOR"
    -O "name;Use custom menu name instead of file name"
    -f "no-capture;Do not capture output of command"
    -f "no-background;Do not send command to background"
    -f "hide-command;Do not show command in menu"
    -f "dry-run;Do not run command"
    -f "debug;Output debug info to stderr"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

debug() {
    set -e
    [[ $FCMD_DEBUG || $args_debug ]] || return 0
    printcolor -s info "$@" >&2
}

check_file() {
    set -e
    stat -c '%U %a' "$1" | grep -q '^root [0-7][0-5][0-5]$' || exit_error "File is not safe: writable by non-root users"
}

[[ -z $args_unsafe_file ]] || args_file=$args_unsafe_file
if [[ $args_file ]]; then
    debug "Running file: $args_file"
    [[ $args_unsafe_file ]] || check_file "$args_file"
    [[ $args_separator ]] || exit_error "No separator found"
    grep "$args_separator" "$args_file" >/dev/null || exit_error "Invalid file (no separator found)"
    menu_name=$(basename "${args_file%.*}")
    [[ -z $args_name ]] || menu_name=$args_name
    debug "Using name: $menu_name"
    export FCMD_PATH="$args_file"
    export FCMD_SEPARATOR="$args_separator"
    export FCMD_HIDE_COMMAND="$args_hide_command"
    export FCMD_DEBUG="$args_debug"
    export FCMD_ALLOW_UNSAFE_FILE="$args_unsafe_file"
    export FCMD_NO_CAPTURE="$args_no_capture"
    export FCMD_NO_BACKGROUND="$args_no_background"
    export FCMD_DRY_RUN="$args_dry_run"
    rofi -show "$menu_name" -modes "$menu_name:$0"
    exit
fi

file_path=$FCMD_PATH
separator=$FCMD_SEPARATOR

debug "Reading file: $file_path"
[[ $FCMD_ALLOW_UNSAFE_FILE ]] || check_file "$file_path"

[[ -f "$file_path" ]] || exit_error "File not found: $file_path"
[[ $separator ]] || exit_error "No separator found"
grep "$separator" "$file_path" >/dev/null || exit_error "Invalid file (no separator found)"

find_line() {
    set -e
    debug "Grepping '^$1'"
    grep "^$1" "$file_path"
}

take_text() {
    set -e
    sed "s/\($separator\).*//"
}

take_command() {
    set -e
    sed "s/.*\($separator\)//" | sed 's/^[[:space:]]*//'
}

if [[ $args_selection ]]; then
    debug "Finding line for $args_selection"
    line=$(find_line "$args_selection")
    debug "Found line: $line"
    command=$(printf "%s" "$line" | take_command)
    debug "Found command: $command"
    run_command() { eval "$command"; }
    encapsulated_command="run_command"
    [[ $FCMD_NO_CAPTURE ]] || encapsulated_command="$encapsulated_command >/dev/null 2>&1"
    [[ $FCMD_NO_BACKGROUND ]] || encapsulated_command="$encapsulated_command &"
    debug "Running command: $command"
    debug "Final evaluation: $encapsulated_command"
    [[ $FCMD_DRY_RUN ]] || eval "$encapsulated_command"
    exit
fi

while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ -z $FCMD_HIDE_COMMAND ]] || line=$(printf "%s" "$line" | take_text)
    echo "$line"
done < "$file_path"
