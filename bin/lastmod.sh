#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Print the last modified entry of a directory"
CLI=(
    --prefix "args_"
    -o "dir-path;Path to directory;."
    -f "first;Show first modified instead of last;;f"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_first ]]; then
    ls -1t "$args_dir_path" | tail -n1
else
    ls -1t "$args_dir_path" | head -n1
fi
