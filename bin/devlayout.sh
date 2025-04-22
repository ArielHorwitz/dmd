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


# CONFIGURATION
config_file=$HOME/.config/${APP_NAME}/config.toml
config_keys=(
    monitors__editor
    monitors__terminal1
    monitors__terminal2
    monitors__git
)
config_default='[monitors]
editor = "eDP-1"
terminal1 = "eDP-1"
terminal2 = "eDP-1"
git = "eDP-1"
'
tt_out=$(mktemp); tt_err=$(mktemp)
if tigerturtle -WD "$config_default" -p "config__" $config_file -- ${config_keys[@]} >$tt_out 2>$tt_err; then
    eval $(<$tt_out); rm $tt_out; rm $tt_err;
else
    echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1;
fi

if [[ $args_absolute ]]; then
    project_dir="$args_dir"
else
    project_dir="$HOME/$args_dir"
fi
project_name=$(basename "$project_dir")

if [[ ! -e $project_dir ]]; then
    mkdir "$project_dir"
    git init "$project_dir"
fi

alacritty_args=(--working-directory "$project_dir")

lite-xl "$project_dir" &
sleep 0.5; hyprctl dispatch movewindow "mon:$config__monitors__editor"
alacritty "${alacritty_args[@]}" &
sleep 0.2; hyprctl dispatch movewindow "mon:$config__monitors__terminal1"
alacritty "${alacritty_args[@]}" &
sleep 0.2; hyprctl dispatch movewindow "mon:$config__monitors__terminal2"
alacritty "${alacritty_args[@]}" --title "$project_name" --command lazygit &
sleep 0.2; hyprctl dispatch movewindow "mon:$config__monitors__git"
