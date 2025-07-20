#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Print the last modified entry of a directory"
CLI=(
    --prefix "args_"
    -o "dir-path;Path to directory;."
    -O "filter;Filter files by pattern (shell glob);*;f"
    -O "file-types;File types (files, dirs, all);files;t"
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

find_args=(
    "$args_dir_path"
    -maxdepth 1
    -name "$args_filter"
)

if [[ $args_file_types = "files" ]]; then
    find_args+=(-type f)
elif [[ $args_file_types = "dirs" ]]; then
    find_args+=(-type d)
elif [[ $args_file_types != "all" ]]; then
    exit_error "Unknown file type: $args_file_types"
fi

find_args+=(-printf "$file_format")

find "${find_args[@]}" | sort "${sort_args[@]}" | head -n1 | cut -d' ' -f2-
