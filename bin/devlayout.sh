#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Open all the necessary windows for a development session."
CLI=(
    --prefix "args_"
    -p "dir;Project directory relative to \$HOME"
    -f "absolute;Consider directory as an absolute path"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_absolute ]]; then
    project_dir="$args_dir"
else
    project_dir="$HOME/$args_dir"
fi
project_name=$(basename "$project_dir")

alacritty_args=(--working-directory "$project_dir")

lite-xl "$project_dir" &
sleep 0.5
alacritty "${alacritty_args[@]}" &
alacritty "${alacritty_args[@]}" &
sleep 0.2
alacritty "${alacritty_args[@]}" --title "$project_name" --hold --command lazygit &
