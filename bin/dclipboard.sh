#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Manage the clipboard"
CLI=(
    --prefix "args_"

    -f "read;Read into the clipboard from stdin"
    -O "read-file;Read into the clipboard from file"
    -f "write;Write the clipboard contents"
    -f "clear;Clear the clipboard"

    -f "copy-history;Open copy from history menu"
    -f "delete-history;Open delete from history menu"
    -f "clear-history;Clear the clipboard manager history"

    -O "suspend-watcher;Temporarily suspend the watcher for a number of seconds"
    -f "enable-watcher;Enable the watcher"
    -f "disable-watcher;Disable the watcher"
    -f "toggle-watcher;Toggle the watcher"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

is_watching() {
    set -e
    if clipcatctl get-watcher-state | grep 'is watching' >/dev/null; then
        return 0
    else
        return 1
    fi
}

clear_clipboard() {
    set -e
    wl-copy --clear
    notify-send -t 3000 "Cleared clipboard"
}

suspend() {
    set -e
    is_watching || exit_error "Cannot suspend if not watching"

    milliseconds=$(("$args_suspend_watcher" * 1000))
    notify-send -t "$milliseconds" "Suspending clipcat watcher for $args_suspend_watcher seconds..."
    clipcatctl disable-watcher
    sleep "$args_suspend_watcher" || :
    clear_clipboard || :
    clipcatctl enable-watcher
}

[[ -z $args_read ]] || clipcatctl load
[[ -z $args_read_file ]] || clipcatctl load --file "$args_read_file"
[[ -z $args_write ]] || clipcatctl save
[[ -z $args_clear ]] || clear_clipboard

if [[ $args_copy_history ]]; then
    clipcat-menu insert
    exit
fi
if [[ $args_delete_history ]]; then
    clipcat-menu remove
    exit
fi
[[ -z $args_clear_history ]] || clipcatctl clear

if [[ "$args_enable_watcher" ]]; then
    clear_clipboard
    clipcatctl enable-watcher
elif [[ "$args_disable_watcher" ]]; then
    clipcatctl disable-watcher
elif [[ "$args_toggle_watcher" ]]; then
    clipcatctl toggle-watcher
fi

[[ -z $args_suspend_watcher ]] || suspend
