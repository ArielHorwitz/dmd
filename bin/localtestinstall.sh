#! /bin/bash

set -e

APP_NAME=$(basename "$0")
ABOUT="Install an executable to local testing bin directory.

In \"Rust mode\", interpret executables as Rust binaries, build them
in release mode, and install them. If no executables are provided, use
the directory name."
CLI=(
    --prefix "args_"
    -c "bin;Executables to install"
    -O "target-dir;Target directory;$HOME/.local/bin/testing"
    -f "keep_suffix;Do not remove suffixes;;k"
    -f "clear;Clear the local testing bin directory;;c"
    -f "rust;Rust mode"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "${CLI}" || exit 1

[[ -z $args_clear ]] || rm -rf "${args_target_dir:?}"/*

if [[ $args_rust ]]; then
    cargo build --release
    if [[ -z $args_bin ]]; then
        args_bin=$(basename "$PWD")
    fi
    cd target/release
fi

if [[ -n $args_bin ]]; then
    mkdir --parents "$args_target_dir"
    for b in "${args_bin[@]}"; do
        target_file=$(basename "$b")
        [[ -n $keep_suffix ]] || target_file=${target_file%.*}
        cp "$b" "$args_target_dir/$target_file"
    done
fi
