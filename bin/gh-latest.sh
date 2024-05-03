#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="DESCRIPTION"
CLI=(
    --prefix "args_"
    -p "repo;Repository in the format of [HOST/]OWNER/REPO"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

list_args=(
    --repo $args_repo
    --exclude-drafts
    --exclude-pre-releases
    --json 'isLatest,tagName'
    --jq '.[] | select(.isLatest == true).tagName'
)

gh release list "${list_args[@]}"
