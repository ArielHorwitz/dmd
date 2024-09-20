#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Get details on the latest version of public GitHub release assets."
CLI=(
    --prefix "args_"
    -p "owner;Owner name (account name)"
    -o "repo;Repo name [defaults to owner name]"
    -f "asset_urls;List asset download URLs;;A"
    -f "prerelease;Allow prereleases;;P"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

repo="${args_owner}/${args_repo:-$args_owner}"
releases=$(curl -sSL https://api.github.com/repos/${repo}/releases)
if [[ -z $args_prerelease ]]; then
    releases=$(jq -r 'map(select(.prerelease == false))' <<< $releases)
fi
latest=$(jq -r '.[0]' <<< $releases)

if [[ -n $args_asset_urls ]]; then
    jq -r '.assets.[].browser_download_url' <<< $latest
else
    jq -r '.tag_name' <<< $latest
fi
