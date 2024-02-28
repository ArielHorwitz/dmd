#! /bin/bash
set -e

DEFAULT_BAT_ARGS=(
    --language markdown
    --color always
    --theme gruvbox-dark
    --style plain
)

APP_NAME=$(basename "$0")
ABOUT="View markdown with bat."
CLI=(
    --prefix "args_"
    -o "file;Read markdown from file instead of stdin"
    -f "always-paging;Always enforce paging;;p"
    -e "bat_args;Arguments for bat"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $args_always_paging ]] || DEFAULT_BAT_ARGS+=(--paging always)

tagmissingnewline $args_file | bat "${DEFAULT_BAT_ARGS[@]}" "${args_bat_args[@]}"

