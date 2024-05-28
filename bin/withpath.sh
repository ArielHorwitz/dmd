#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Print PATH with a new path (while avoiding duplication)."
CLI=(
    --prefix "args_"
    -C "path;New paths to add"
    -f "prepend;Prepend path instead of appending;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1


for new_path in "${args_path[@]}"; do
    if [[ ":$PATH:" != *:"$new_path":* ]]; then
        if [[ -n $args_prepend ]]; then
            PATH="$new_path${PATH:+:$PATH}"
        else
            PATH="${PATH:+$PATH:}$new_path"
        fi
    fi
done

echo -n "$PATH"
