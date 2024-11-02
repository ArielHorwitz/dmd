#! /bin/bash
set -e

CONFIG_FILE=$HOME/.config/gamma

APP_NAME=$(basename "$0")
ABOUT="Set the gamma for connected displays."
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

if [[ $args_multiplier ]]; then
    multi=$args_multiplier
else
    [[ -f $args_config_path ]] || echo "1.0" > $args_config_path
    multi=$(< $args_config_path)
fi

read -r gamma < <(awk \
    -v m="$multi" -v r="$args_red" -v g="$args_green" -v b="$args_blue" \
    'BEGIN {printf "%.3f:%.3f:%.3f\n", m*r, m*g, m*b}')

while read -r monitor; do
    xrandr --output "$monitor" --gamma "$gamma" &
done < <(xrandr -q | awk '/ connected/{print $1}')
