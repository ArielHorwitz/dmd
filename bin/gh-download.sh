#! /bin/bash
set -e

DEFAULT_INSTALL_LOCATION=$HOME/.local/bin

APP_NAME=$(basename "$0")
ABOUT="Install binary from GitHub repo release."
CLI=(
    --prefix "args_"
    -p "repo;Repository in the form of [HOST/]OWNER/REPO"
    -o "binary;Binary name [defaults to name of repo]"
    -O "version;Install a specific version [defaults to latest];;v"
    -O "target;Install location;$DEFAULT_INSTALL_LOCATION;t"
    -f "force;Force (clobber existing file);;f"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

[[ -n $args_force ]] && args_force="--clobber" || args_force=""
if [[ -z $args_version ]]; then
    args_version=$(gh-latest)
fi
printcolor -ns info "Version:"; echo $args_version

if [[ -z $args_binary ]]; then
    args_binary=$(echo $args_repo | awk -F '/' '{print $NF}')
fi
printcolor -ns info "Downloading: "; echo "$args_binary"

local_filepath=$args_target/$args_binary
printcolor -ns info "Installing to: "; echo "$(dirname $local_filepath)"

gh release download $args_force --repo $args_repo $args_version -p "$args_binary" -O $local_filepath
chmod +x $local_filepath

printcolor -s ok "Installed "; echo $args_binary
