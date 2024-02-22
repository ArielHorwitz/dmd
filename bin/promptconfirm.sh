#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Prompt the user for confirmation. Defaults to accept."
CLI=(
    -o "text;Prompt text (is passed through tcprint);Confirm?"
    -O "timeout;Timeout in seconds;;t"
    -f "raw-text;Do not pass through tcprint;;r"
    -f "deny;Deny by default;;d"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

if [[ -n $timeout ]]; then
    timeout_indicator="[${timeout}s]"
    timeout="-t $timeout"
fi

# Prompt
[[ -n $deny ]] && yesno="(y/N)" || yesno="(Y/n)"
if [[ $raw_text ]]; then
    printf "%s" "$text"
elif [[ $text == *]* ]]; then
    tcprint "n $text"
else
    tcprint "n]$text"
fi
printf " \e[35m%s\e[2;37m%b\e[0m " "$yesno" "$timeout_indicator"
read $timeout -n 1 answer || answer_timeout=1

# Print newline
# A known bug is when non-newline whitespace is entered then a newline is not printed
# Missing a way to differentiate between newline and other whitespace
if [[ $answer_timeout -eq 0 && -n $answer || $answer_timeout -eq 1 ]]; then
    echo
fi

if [[ -n $deny ]]; then
    # Deny by default (--deny)
    [[ -n $answer && "yY" == *$answer* ]] && exit 0 || exit 1
fi

# Accept by default
[[ -n $answer && "nN" == *$answer* ]] && exit 1 || exit 0

