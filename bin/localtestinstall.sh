#! /bin/bash

set -e

APP_NAME=$(basename "$0")
ABOUT="Install an executable to local testing bin directory."
CLI=(
    --prefix "args_"
    -c "bin;Executables to install"
    -O "target-dir;Target directory;$HOME/.local/bin/testing"
    -f "keep_suffix;Do not remove suffixes;;k"
    -f "clear;Clear the local testing bin directory;;c"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "${CLI}" || exit 1

[[ -z $args_clear ]] || rm -rf "${args_target_dir:?}"/*

[[ -n $args_bin ]] || exit

mkdir --parents "$args_target_dir"
for b in "${args_bin[@]}"; do
    target_file=$(basename "$b")
    [[ -n $keep_suffix ]] || target_file=${target_file%.*}
    cp "$b" "$args_target_dir/$target_file"
done
