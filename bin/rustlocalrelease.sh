#! /bin/bash

set -e

cargo build --release
executable="$1"
if [[ -z $executable ]]; then
    executable="$(basename $PWD)"
fi
cp target/release/$executable ~/.local/bin/
