#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Generate pseudo-random data and copy to the clipboard"
CLI=(
    --prefix "args_"
    -o "count;Number of characters or digits;6;c"
    -o "mode;Mode of operation [one of: digits, chars, alnum, hex, printable];alnum"
    -f "no-clipboard;Do not copy to clipboard (print only);;n"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

case $args_mode in
    digits    )   filter='[:digit:]' ;;
    chars     )   filter='[:alpha:]' ;;
    alnum     )   filter='[:alnum:]' ;;
    hex       )   filter='0-9A-F' ;;
    printable )   filter='[:print:]' ;;
    *         )   exit_error "Unknown mode '$args_mode'" ;;
esac

output=$(</dev/urandom tr -dc "$filter" | head -c $args_count)
echo "$output"
[[ -n $args_no_clipboard ]] || printf "%s" "$output" | clipcatctl load
