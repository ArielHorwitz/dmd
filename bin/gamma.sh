#! /bin/bash
set -e

CONFIG_FILE=$HOME/.config/gamma

APP_NAME=$(basename "$0")
ABOUT="DESCRIPTION"
CLI=(
    --prefix "args_"
    -o "multiplier;Override the base the multiplier value"
    -O "red;Set the red value;1.0;r"
    -O "green;Set the green value;1.0;g"
    -O "blue;Set the blue value;1.0;b"
    -O "config-path;Config file path;$CONFIG_FILE"
    -f "save;Save multiplier value to config and exit"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ -n $args_save ]]; then
    echo "${args_multiplier:-1.0}" > $args_config_path
fi

[[ -f $args_config_path ]] || echo "1.0" > $args_config_path

multi=${args_multiplier:-$(cat $args_config_path)}

red=$(bc <<< "$multi * $args_red")
green=$(bc <<< "$multi * $args_green")
blue=$(bc <<< "$multi * $args_blue")
gamma=$red:$green:$blue


set +e
for monitor in $(xrandr -q | grep " connected" | awk '{print $1}') ; do
    echo "$monitor $gamma" >&2
    xrandr --output $monitor --gamma $gamma
done
