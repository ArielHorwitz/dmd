#! /bin/bash

set -e


APP_NAME=$(basename "$0")
ABOUT="Build in release mode and install using `localtestinstall`."
CLI=(
    -o "bin;Executable to install"
    -f "clear;Clear the local testing bin directory;;c"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


cargo build --release
if [[ -z $bin ]]; then
    bin="$(basename $PWD)"
fi

[[ -z $clear ]] || CLEAR="--clear"
localtestinstall $CLEAR target/release/$bin

