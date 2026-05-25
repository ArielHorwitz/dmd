#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Apply home directory using homux with location-based selections"
CLI=(
    --prefix "args_"
    -O "state-file;Path to location state file;${HOME}/.local/state/dmd/location"
    -c "select;Homux selections (default: read from state file)"
    -O "config-file;Path to homux config file;;c"
    -f "verbose;Verbose homux output;v"
    -f "reload;Reload config after applying;r"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1
PERMS_DIR="$HOME/.config/dmd/perms"
POST_HOOK="$HOME/.config/dmd/hooks/post.sh"

selections=()
if [[ ${#args_select[@]} -gt 0 ]]; then
    selections=("${args_select[@]}")
elif [[ -f "$args_state_file" ]]; then
    location=$(cat "$args_state_file")
    [[ -n "$location" ]] && selections+=("$location")
fi

homux_args=()
if [[ -n "$args_config_file" ]]; then
    homux_args+=(--config-file "$args_config_file")
fi
homux_args+=(apply)
if [[ "$args_verbose" ]]; then
    homux_args+=(--verbose)
fi
if [[ ${#selections[@]} -gt 0 ]]; then
    for sel in "${selections[@]}"; do
        homux_args+=(-s "$sel")
    done
    hostname=$(hostnamectl hostname)
    homux_args+=(-s "$hostname")
fi

echo "Applying homux: ${homux_args[*]}"
homux "${homux_args[@]}"

if [[ -d "$PERMS_DIR" ]]; then
    for perm_file in "$PERMS_DIR"/*; do
        [[ -f "$perm_file" ]] || continue
        perm=$(basename "$perm_file")
        while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            target_path="$HOME/$path"
            if [[ ! -e "$target_path" ]]; then
                echo "Ignoring chmod for non-existent path: $target_path" >&2
                continue
            fi
            chmod "$perm" "$target_path"
        done < "$perm_file"
    done
fi

if [[ -f "$POST_HOOK" ]]; then
    bash "$POST_HOOK"
fi

if [[ "$args_reload" ]]; then
    reload-config
fi
