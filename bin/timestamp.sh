#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Generate a sortable timestamp and copy to the clipboard."
CLI=(
    --prefix "args_"
    -f "no-date;Do not include date;;d"
    -f "no-time;Do not include hours/minutes;;t"
    -f "no-seconds;Do not include seconds;;s"
    -f "milliseconds;Include milliseconds;;m"
    -f "microseconds;Include microseconds;;c"
    -f "clipboard;Copy to clipboard;;C"
    -O "num-delim;Delimiter between numbers;-"
    -O "date-delim;Delimiter between date and time;__"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

format=""
if [[ -z $args_no_date ]]; then
    format="+%Y${args_num_delim}%m${args_num_delim}%d"
fi
if [[ -z $args_no_time ]]; then
    format="${format:+${format}${args_date_delim}}%H${args_num_delim}%M"
    if [[ -z $args_no_seconds ]]; then
        format+="${args_num_delim}%S"
        if [[ $args_microseconds ]]; then
            format+="${args_num_delim}$(date '+%N' | cut -b-6)"
        elif [[ $args_milliseconds ]]; then
            format+="${args_num_delim}$(date '+%N' | cut -b-3)"
        fi
    fi
fi
[[ $format ]] || exit_error "No format options selected"
output=$(date "$format")
echo "$output"
if [[ $args_clipboard ]]; then
    printf "%s" "$output" | clipcatctl load
fi
