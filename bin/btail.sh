#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="tail to bat"
CLI=(
    --prefix "args_"
    -c "files;Files to tail (or none for stdin)"
    -O "lines;Lines to preload in tail;500"
    -f "log;Use log syntax in bat;;l"
    -f "line-numbers;Show line numbers in bat;;n"
    -e "bat_args;Arguments for bat"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

tail_args=(-n "$args_lines")
if [[ $args_files ]]; then
    tail_args+=(-F "${args_files[@]}")
fi

bat_args=(--paging=never)
if [[ $args_log ]]; then
    bat_args+=(-l log)
fi
if [[ $args_line_numbers ]]; then
    bat_args+=(-n)
fi
bat_args+=("${args_bat_args[@]}")

tail "${tail_args[@]}" | bat "${bat_args[@]}"
