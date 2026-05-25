#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Watch for monitor changes to detect location"
CLI=(
    --prefix "args_"
    -O "config;Path to monitor-locations config file;${HOME}/.config/dmd/monitor-locations.conf;c"
    -O "state-file;Path to write location state;${HOME}/.local/state/dmd/location;s"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

PIDFILE="/tmp/${APP_NAME}.pid"
if [[ -f "$PIDFILE" ]]; then
    old_pid=$(cat "$PIDFILE")
    if kill -0 "$old_pid" 2>/dev/null; then
        echo "Killing existing $APP_NAME (pid $old_pid)"
        kill "$old_pid"
        sleep 0.5
    fi
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

declare -A MONITOR_MAP

load_config() {
    MONITOR_MAP=()
    while IFS='=' read -r serial location; do
        serial=$(echo "$serial" | xargs)
        location=$(echo "$location" | xargs)
        [[ -z "$serial" || "$serial" == \#* ]] && continue
        MONITOR_MAP["$serial"]="$location"
    done < "$args_config"
}

detect_location() {
    local serial location
    while read -r serial; do
        [[ -z "$serial" ]] && continue
        location="${MONITOR_MAP[$serial]:-}"
        if [[ -n "$location" ]]; then
            echo "$location"
            return
        fi
    done < <(hyprctl monitors -j | jq -r '.[].serial')
}

write_location() {
    local detected
    detected=$(detect_location)
    local current=""
    [[ -f "$args_state_file" ]] && current=$(cat "$args_state_file")
    if [[ "$detected" != "$current" ]]; then
        echo "$(date): location changed: '${current}' -> '${detected}'"
        mkdir -p "$(dirname "$args_state_file")"
        echo -n "$detected" > "$args_state_file"
        notify-send -h "string:synchronous:$APP_NAME" "Monitor Watchdog" "Location: ${detected:-<none>}"
    fi
}

if [[ ! -f "$args_config" ]]; then
    echo "Config file not found: $args_config" >&2
    exit 1
fi

load_config
write_location

socat -U - UNIX-CONNECT:"$SOCKET_PATH" | while read -r line; do
    if [[ "$line" == "monitoradded>>"* || "$line" == "monitorremoved>>"* ]]; then
        sleep 1
        write_location
    fi
done
