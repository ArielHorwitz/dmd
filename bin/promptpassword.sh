#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Prompt user for password.

Uses 'systemd-ask-password' if available, otherwise defaults to 'read'.
Timeout of 0 is invalid because of differences between implementations."
CLI=(
    --prefix "args_"
    -o "prompt;Prompt text"
    -O "cache;Use cache by a given name"
    -O "timeout;Timeout waiting for password in seconds;90;t"
    -O "implementation;Choose implementation (one of: auto, read, systemd);auto"
    -f "hide;Hide input entirely (don't show asterisks);;H"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

[[ $args_timeout -ne 0 ]] || exit_error "Timeout of 0 is undefined."

ask_using_systemd() {
    set -e
    ask_password_args=(-n --emoji=no --timeout=$args_timeout)
    [[ -z $args_hide ]] || ask_password_args+=(--echo=no)
    [[ -z $args_cache ]] || ask_password_args+=(--accept-cached --keyname="$args_cache")
    [[ $args_prompt ]] && ask_password_args+=("$args_prompt") || ask_password_args+=('')
    systemd-ask-password "${ask_password_args[@]}"
}

ask_using_read() {
    set -e
    IFS=
    local user_input=
    local user_input_char=
    [[ -z $args_prompt ]] || printf "${args_prompt} " >&2
    while :; do
        read -rsn1 -d '' user_input_char
        if [[ $user_input_char == $'\x7f' ]]; then
            if [[ -n $user_input ]]; then
                user_input="${user_input%?}"
                echo -en "\b \b" >&2
            fi
        elif [[ $user_input_char == $'\x0a' ]]; then
            break
        else
            user_input+="$user_input_char"
            [[ $args_hide ]] || printf '*' >&2
        fi
    done
    echo >&2

    printf "%s" "$user_input"
    IFS=' '
}

case $args_implementation in
    read          ) ask_using_read ;;
    systemd       ) ask_using_systemd ;;
    auto          ) command -v systemd-ask-password >/dev/null && ask_using_systemd || ask_using_read ;;
esac
