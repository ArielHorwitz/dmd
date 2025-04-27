#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Send every line from stdin to a notification"
CLI=(
    --prefix "args_"
    -O "cap;Maximum number of characters to show for each line;100"
    -O "title;Title of notifications;Line on stdin:;t"
    -O "end-title;Title of notification on finish;stdin EOF"
    -f "count;Count lines;;c"
    -f "separate;Send each line to a separate notification;;s"
    -f "quiet;Do not print lines to stdout;;q"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

notify_args=()
if [[ -z $args_separate ]]; then
    notify_args+=("-h" "string:synchronous:$APP_NAME")
fi

count=0
while read -r line || [[ -n $line ]]; do
    count=$(("$count" + 1))
    if [[ -z $args_quiet ]]; then
        echo "$line"
    fi
    if [[ $args_count ]]; then
        title="[${count}] $args_title"
    else
        title="$args_title"
    fi
    notify-send "${notify_args[@]}" "$title" "${line:0:args_cap}"
done

notify-send "${notify_args[@]}" "$args_end_title" "Total lines: $count"
