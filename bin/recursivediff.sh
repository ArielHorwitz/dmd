#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Compare sha256 sums of directories recursively"
CLI=(
    --prefix "args_"
    -p "dir1;Directory 1"
    -p "dir2;Directory 2"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

recursive_sha() {
    set -e
    local dirpath=$1
    find "$dirpath" -type f -exec sha256sum {} + \
        | sed "s|${dirpath}/||" | awk '{print $2 " " $1}' \
        | sort
}

dir1=$(realpath "$args_dir1")
dir2=$(realpath "$args_dir2")
tmpdir=$(mktemp -d)

recursive_sha "$dir1" > "${tmpdir}/dir1.sha"
recursive_sha "$dir2" > "${tmpdir}/dir2.sha"

diff --left-column "$tmpdir"/*

rm -r "$tmpdir"
