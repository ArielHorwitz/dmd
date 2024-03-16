#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Open the last modified file using xdg-open."
CLI=(
    --prefix "args_"
    -o "dir;Directory to browse;."
    -f "noopen;Print file only without opening;;n"
    -f "quiet;Do not print file name;;q"
    -f "wait;Wait for child process;;w"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI"
eval "$CLI" || exit 1

# Resolve file
dir_path=$(realpath $args_dir)
if [[ -f $dir_path ]]; then
    dir_path=$(dirname $dir_path)
fi
last_modified_file=$(ls -1t $dir_path | head -n1)

# Print
if [[ -z $args_quiet ]]; then
    echo $last_modified_file
fi

# Open
if [[ -n $args_noopen ]]; then
    exit
fi
if [[ -n $args_wait ]]; then
    xdg-open $last_modified_file
else
    xdg-open $last_modified_file &
fi
