#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Extract archives."
CLI=(
    --prefix "args_"
    -p "archive;Archive file"
    -o "target-dir;Directory for extraction;."
    -f "no-subdir;Do not create a subdirectory;;D"
    -f "list;List contents instead of extracting;;l"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_list ]]; then
    tar --list --file "$args_archive"
    exit
fi

# Resolve and create target directory
archive_name=$(basename "$args_archive")
if [[ $args_no_subdir ]]; then
    target_dir="${args_target_dir}"
else
    target_dir="${args_target_dir}/${archive_name%%.*}"
fi
mkdir -p "$target_dir"

# Decompress
tar_args=(
    --directory "$target_dir"
    --extract
    --file "$args_archive"
)
tar "${tar_args[@]}"
