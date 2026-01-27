#! /bin/bash

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Check for and download updates."
CLI=(
    --prefix "args_"
    -f "download;Download updates only;;d"
    -f "notify;Show notifications;;n"
    -O "retry;Number of retry attempts with 2 minute delay;3;r"
    -O "retry-interval;Number of seconds between retry attempts;120"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

[[ "$(id -u)" -ne 0 ]] || exit_error "Must not be run as root."

print_msg() {
    local status=$1
    local message=$2
    local submessage=$3

    printcolor -s "$status" "$message $submessage"
    if [[ $args_notify ]]; then
        criticality="normal"
        [[ $status == "ok" || $status == "info" ]] || criticality="critical"
        notify-send -h string:synchronous:check-updates-script -u $criticality "$message" "$submessage"
    fi
}

for attempt in $(seq 1 $args_retry); do
    print_msg info "Checking for updates..."
    updates=$(checkupdates 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 || $exit_code -eq 2 ]]; then
        break
    fi

    if [[ $attempt -lt $args_retry ]]; then
        print_msg warn "System update check failed." "Retrying in $args_retry_interval seconds..."
        sleep $args_retry_interval
    else
        submessage=
        if [[ $attempt -gt 1 ]]; then
            submessage="Failed after $args_retry attempts."
        fi
        print_msg error "System update check failed." "$submessage"
        exit 1
    fi
done

updates_count=$(echo "$updates" | wc -l)


if [[ $updates ]]; then
    print_msg ok "${updates_count} system updates available."
else
    print_msg ok "No system updates available."
fi

if [[ $args_download ]]; then
    print_msg ok "Downloading system updates..."
    sudo checkupdates --download || exit 1
else
    [[ $updates ]] && exit 0 || exit 1
fi
