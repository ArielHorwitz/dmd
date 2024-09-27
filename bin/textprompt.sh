#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Read input."
CLI=(
    --prefix "args_"
    -f "multiline;Enable multiline input (ctrl+d to end);;m"
    -f "hide;Hide input text;;H"
    -f "no-newline;Disable printing newline after reading;;n"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

IFS=
user_input=
while :; do
    read -rsn1 -d '' user_input_char
    if [[ $user_input_char == $'\x7f' ]]; then
        if [[ -n $user_input ]]; then
            user_input="${user_input%?}"
            echo -en "\b \b" >&2
        fi
    elif [[ $user_input_char == $'\x04' ]]; then
        break
    elif [[ $user_input_char == $'\x0a' ]]; then
        if [[ -n $args_multiline ]]; then
            user_input+=$'\n'
            [[ -n $args_hide ]] && printf '*' || printf "\n" >&2
        else
            break
        fi
    else
        user_input+="$user_input_char"
        [[ -n $args_hide ]] && printf '*' || printf "%s" "$user_input_char" >&2
    fi
done
[[ $args_no_newline ]] || echo >&2

printf "%s" "$user_input"
