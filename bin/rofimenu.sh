#! /bin/bash
set -e

EXECUTABLE_PATH=/bin/dmd
EXECUTABLE_PREFIX="${EXECUTABLE_PATH}/rofimenu-"

# CLI
APP_NAME=$(basename "$0")
ABOUT="Run custom menus via rofi"
CLI=(
    --prefix "args_"
    -o "menu;Menu name (leave blank to list menus)"
    -f "no-fuzzy;Do not enable fuzzy search"
    -O "dpi;Set dpi;0"
    -e "menu_arguments;Extra arguments for the menu script"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

rofi_args=(
    -show "$args_menu"
    -modes "${args_menu}:${EXECUTABLE_PREFIX}${args_menu} ${args_menu_arguments[@]}"
    -dpi "$args_dpi"
)
if [[ $args_no_fuzzy ]]; then
    rofi_args+=(-matching normal)
fi

if [[ $args_menu ]]; then
    rofi "${rofi_args[@]}"
else
    printcolor -ou -ob "Available menus:" >&2
    basename -a "${EXECUTABLE_PATH}"/rofimenu-* | sed 's/rofimenu-//g'
fi
