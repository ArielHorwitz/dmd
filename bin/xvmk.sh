#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Make archives."
CLI=(
    --prefix "args_"
    -p "target;Target archive name"
    -c "source;Directory or files to archive"
    -O "no-compression;Do not use compression"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

tar_args=(
    --create
    --file "${args_target}.tar.gz"
)
if [[ -z $args_no_compression ]]; then
    tar_args+=(--gzip)
fi
tar "${tar_args[@]}" "${args_source[@]}"
