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

sort_args=(--numeric-sort)
if [[ -z $args_first ]]; then
    sort_args+=(--reverse)
fi

find "$args_dir_path" -maxdepth 1 -type f -printf '%T@ %p\n' | sort "${sort_args[@]}" | head -n1 | cut -d' ' -f2-
