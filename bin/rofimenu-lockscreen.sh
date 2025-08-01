#! /bin/bash
set -e

IMAGES_DIR=$HOME/media/walls
IMG_NAME=.lockscreen.png

# CLI
APP_NAME=$(basename "$0")
ABOUT="Set lockscreen image from rofi"
CLI=(
    --prefix "args_"
    -o "image;Select image"
    -f "run;Run in rofi;;r"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_run ]]; then
    rofi -show "lockscreen" -modes "lockscreen:$0"
fi

if [[ -z "$args_image" ]]; then
    ls -1 "$IMAGES_DIR"
    exit
fi

if [[ "$args_image" = *.png ]]; then
    cp "$IMAGES_DIR/$args_image" "$IMAGES_DIR/$IMG_NAME"
else
    magick "$IMAGES_DIR/$args_image" "$IMAGES_DIR/$IMG_NAME"
fi
