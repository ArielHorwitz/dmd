#! /bin/bash
set -e

LOG_DIR=/tmp/logs-$USER
LOG_FILE=$LOG_DIR/kmdrun
CATFILE_DIR=/tmp/kmonad
CONFIG_DIR=$HOME/.config/kmd
DEFAULT_DEVICES_FILE=$CONFIG_DIR/devices
KBD_DIR=$CONFIG_DIR/kbd
ICON_LOAD=/usr/share/icons/dmd/loading.svg
ICON_START=/usr/share/icons/dmd/keyboard.svg
NOTIFY_SYNC_ARG="string:synchronous:kmd"

APP_NAME=$(basename "$0")
ABOUT="Run KMonad."
CLI=(
    --prefix "args_"
    -c "devices;Devices to enable"
    -O "device-file;File of devices to enable;${DEFAULT_DEVICES_FILE};d"
    -f "debug;Enable debug mode;;D"
    -f "fail;Fail if a device cannot be found"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

[[ $EUID -eq 0 ]] && exit_error "Do not run $APP_NAME as root."

echo "Logging to: $LOG_FILE"
exec >>$LOG_FILE 2>&1

log() {
    timestamp=$(date +"%Y-%m-%d %T")
    echo "$timestamp | $@"
}

# Create default config
[[ -d $CONFIG_DIR ]] || mkdir --parents $CONFIG_DIR
if [[ ! -f $DEFAULT_DEVICES_FILE ]]; then
    echo "# Find available devices by running 'find /dev/input/by-* -type l'" > $DEFAULT_DEVICES_FILE
fi
mkdir --parents $KBD_DIR
mkdir --parents $CATFILE_DIR

cd

kmonad_args=()
[[ -z $args_debug ]] || kmonad_args+=(-l debug)

run_kmonad() {
    set -e
    local device_path=$1
    local device_name=$(basename $device_path)
    local sync_arg=${NOTIFY_SYNC_ARG}-$device_name
    local device_log_file=${LOG_DIR}/kmd-${device_name}.log

    # Create (combine) new config file
    kbd_file=$CATFILE_DIR/$device_name.kbd
    log $(printcolor -ns info "KMonad config file: "; echo $kbd_file)
    cat $KBD_DIR/* > $kbd_file

    # Insert device path
    sed -i "s|<KMD_DEVICE_PATH>|${device_path}|" $kbd_file
    # Insert start command
    start_command="notify-send -h ${sync_arg} -i ${ICON_START} \'Started KMonad\' \'${device_name}\'"
    sed -i "s|<KMD_START_CMD>|${start_command}|" $kbd_file

    # Kill running instance of KMonad
    local running_pid=$(pgrep -ax kmonad | grep $device_name | awk '{print $1}' || echo '')
    if [[ -n $running_pid ]]; then
        sleep 0.1
        kill $running_pid
    fi
    setlayer base

    # Start KMonad
    log "Starting KMonad: $device_name (logging to: $device_log_file)"
    notify-send -h ${sync_arg} -i ${ICON_LOAD} -u low "Starting KMonad..." "$device_name"
    kmonad $kbd_file ${kmonad_args[@]} >${device_log_file} 2>&1 &
}

available_devices=$(find /dev/input/by-* -type l)
mapfile devices_from_file <<< $(decomment $args_device_file)
enable_devices=(${args_devices[@]} ${devices_from_file[@]})

for some_device in ${enable_devices[@]} ; do
    device_path=$(echo "$available_devices" | grep $some_device || echo '')
    if [[ -z $device_path ]]; then
        [[ -z $args_fail ]] || exit_error "Device unavailable: $some_device"
        continue
    fi
    log $(printcolor -ns ok "Enabling device: "; printcolor -s info "${some_device}")
    run_kmonad $device_path
done
