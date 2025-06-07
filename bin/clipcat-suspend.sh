#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Suspend clipcat watcher"
CLI=(
    --prefix "args_"
    -o "seconds;Number of seconds to suspend;5"
    -f "enable;Enable the watcher;;e"
    -f "disable;Disable the watcher;;d"
    -f "toggle;Toggle the watcher;;t"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1


if [[ "$args_enable" ]]; then
    clipcatctl enable-watcher
    exit
elif [[ "$args_disable" ]]; then
    clipcatctl disable-watcher
    exit
elif [[ "$args_toggle" ]]; then
    clipcatctl toggle-watcher
    exit
fi

if clipcatctl get-watcher-state | grep 'not'; then
    exit
fi

notify-send -t "$((args_seconds * 1000))" "Suspending clipcat watcher for $args_seconds seconds..."
clipcatctl disable-watcher
sleep "$args_seconds" || :
clipcatctl enable-watcher
