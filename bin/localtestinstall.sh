#! /bin/bash

set -e
BINDIR="$HOME/.local/bin/testing"

APP_NAME=$(basename "$0")
ABOUT="Install an executable to local testing bin directory."
CLI=(
    -o "bin;Executable file to install"
    -f "path;Print the path to the local testing bin directory and exit;;p"
    -f "keep-suffix;Do not remove the suffix;;k"
    -f "clear;Clear the local testing bin directory;;c"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $path ]] || { echo $BINDIR ; exit 0 ; }
[[ -z $clear ]] || rm -rf $BINDIR/*
if [[ -n "$bin" ]]; then
    target="$(basename $bin)"
    [[ -z $keep_suffix ]] || target="${target%.*}"
    cp "$bin" "$BINDIR/$target"
fi

