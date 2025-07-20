#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Print the last modified entry of a directory"
CLI=(
    --prefix "args_"
    -o "dir-path;Path to directory;."
    -O "filter;Filter files by pattern (shell glob);*;f"
    -f "first;Show first modified instead of last;;F"
    -f "name;Consider name instead of modified time;;n"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

sort_args=(--numeric-sort)
if [[ -z $args_first ]]; then
    sort_args+=(--reverse)
fi

file_format='%T@ %p\n'
if [[ $args_name ]]; then
    file_format='0 %p\n'
fi

find "$args_dir_path" -maxdepth 1 -type f -name "$args_filter" -printf "$file_format" | sort "${sort_args[@]}" | head -n1 | cut -d' ' -f2-
