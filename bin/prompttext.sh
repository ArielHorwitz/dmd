#! /bin/bash
set -e

USER_INPUT_FILE=/tmp/prompttextuserinput
DEFAULT_PROMPT_ARGS=(--no-newline --foreground magenta)

APP_NAME=$(basename "$0")
ABOUT="Prompt the user for a single line of text.

To use effectively, run once and then get the user input by evaluating with '--read':
$APP_NAME; user_input=\$($APP_NAME --read)"
CLI=(
    --prefix "args_"
    -o "prompt;Print prompt before reading input;> "
    -f "hide;Hide input text;;H"
    -f "read;Print the last input text;;R"
    -f "no-prompt;Disable printing prompt;;P"
    -f "no-newline;Disable printing newline after reading;;N"
    -e "prompt_args;Arguments for printcolor prompt"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

# Read file - don't prompt
if [[ -n $args_read ]]; then
    cat $USER_INPUT_FILE
    exit 0
fi

# Print prompt for user
if [[ -z $args_no_prompt ]]; then
    if [[ -n $args_prompt_args ]]; then
        prompt_args=${args_prompt_args[@]}
    else
        prompt_args=${DEFAULT_PROMPT_ARGS[@]}
    fi
    printcolor ${prompt_args[@]} "$args_prompt"
fi

# Empty file
printf "" > $USER_INPUT_FILE

# Read input from user
IFS=''
user_input=''
while :; do
    read -sn1 user_input_char
    if [[ $user_input_char == $'\x7f' ]]; then
        if [[ -n $user_input ]]; then
            user_input="${user_input%?}"
            echo -en "\b \b"
        fi
    elif [[ -z $user_input_char ]]; then
        break
    else
        user_input+="$user_input_char"
        [[ -n $args_hide ]] && printf '*' || printf "%s" "$user_input_char"
    fi
done
if [[ -z $args_no_newline ]]; then
    echo
fi

# Write to file
printf "%s" $user_input > $USER_INPUT_FILE
