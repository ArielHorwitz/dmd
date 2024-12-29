#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Run a command on an interval"
CLI=(
    --prefix "args_"
    -o "interval;Interval between executions in seconds;2.0"
    -f "noclear;Do not clear the screen before each execution;;C"
    -f "notime;Show timestamp after each execution;;T"
    -e "command;Command to run"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

tput civis
while :; do
    output=$(${args_command[@]})
    [[ -n $args_noclear ]] || clear
    [[ -n $args_notime ]] || printcolor -o bold -o underline "$(date '+%y/%m/%d %H:%M:%S')"
    printf "$output"
    read -t $args_interval -sn1 user_input_char || user_input_char=
    if [[ $user_input_char = 'q' ]]; then
        break
    elif [[ $user_input_char = 't' && -n $args_notime ]]; then
        args_notime=
    elif [[ $user_input_char = 't' && -z $args_notime ]]; then
        args_notime=1
    fi
done
echo
tput cnorm
