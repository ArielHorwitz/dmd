#! /bin/bash
set -e

IMAGES_DIR=$HOME/media/walls
IMG_NAME=.wallpaper.png

selection=$(ls -1 "$IMAGES_DIR" | fuzzel --dmenu --mesg "Set a wallpaper image")
[[ -n $selection ]] || exit 0

hyprctl hyprpaper wallpaper ,"$IMAGES_DIR/$selection" >&2

if [[ "$selection" = *.png ]]; then
    cp "$IMAGES_DIR/$selection" "$IMAGES_DIR/$IMG_NAME"
else
    magick "$IMAGES_DIR/$selection" "$IMAGES_DIR/$IMG_NAME"
fi
