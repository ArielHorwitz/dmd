#! /bin/bash
set -e

IMAGES_DIR=$HOME/media/walls
IMG_NAME=.lockscreen.png

selection=$(ls -1 "$IMAGES_DIR" | fuzzel --dmenu --mesg "Pick a lockscreen image")
[[ -n $selection ]] || exit 0

if [[ "$selection" = *.png ]]; then
    cp "$IMAGES_DIR/$selection" "$IMAGES_DIR/$IMG_NAME"
else
    magick "$IMAGES_DIR/$selection" "$IMAGES_DIR/$IMG_NAME"
fi
