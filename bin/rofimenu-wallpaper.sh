#! /bin/bash
set -e

IMAGES_DIR=$HOME/media/walls
IMG_NAME=.wallpaper.png

if [[ -z "$1" ]]; then
    ls -1 "$IMAGES_DIR"
    exit
fi

hyprctl hyprpaper reload ,"$IMAGES_DIR/$1" >&2

if [[ "$1" = *.png ]]; then
    cp "$IMAGES_DIR/$1" "$IMAGES_DIR/$IMG_NAME"
else
    magick "$IMAGES_DIR/$1" "$IMAGES_DIR/$IMG_NAME"
fi
