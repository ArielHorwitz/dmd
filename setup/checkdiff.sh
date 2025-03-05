#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Check the difference between local files and installable files."
CLI=(
    --prefix "args_"
    -e "homux;Homux select (homux apply --select)"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

staging_home=$(homux apply -d ${args_homux[@]} | grep 'to target directory' | cut -d':' -f2 | awk '{print $1}')

diff_found=0

for relative_file in $(cd "$staging_home" && find . -type f); do
    local_file=$(realpath "$HOME/$relative_file")
    staging_file=$(realpath "$staging_home/$relative_file")
    diff_command=(diff --color=always "${diff_args[@]}" "$staging_file" "$local_file")
    if ! "${diff_command[@]}" >/dev/null; then
        printcolor -ob -od -fy "[$relative_file]"
        "${diff_command[@]}" || :
        diff_found=1
    fi
done

test $diff_found -eq 0
