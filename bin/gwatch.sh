#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Run a command when files tracked by git are modified."
CLI=(
    --prefix "args_"
    -O "file-trigger;Command listing files;git ls-files;t"
    -f "no-time;Disable time after command;;T"
    -f "no-hint;Disable hints after command;;H"
    -f "quiet;Disable all output other than the command;;q"
    -e "command;Command to run"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

[[ -n $args_command ]] || args_command=('echo' 'Files modified:')

command="${args_command[@]}"

if [[ -z $args_no_time && -z $args_quiet ]]; then
    command+=';'"printcolor -nrf magenta"
    command+='; date "+%y/%m/%d %H:%M:%S" | tr -d "\n"'
    command+='; printcolor -n " "'
    command+="; printcolor -nf magenta -o dim \"[${args_file_trigger}]\""
fi
if [[ -z $args_no_hint && -z $args_quiet ]]; then
    [[ -n $args_no_time ]] || command+='; echo'
    command+='; printcolor -nf red -o dim "Exit (break): ^Z "'
    command+='; printcolor -nf yellow -o dim "Refresh files: ^C "'
    command+='; printcolor -nf green -o dim "Rerun command: space"'
fi

set +e

while :; do
    ${args_file_trigger[@]} | entr -drc bash -c "$command"
done
