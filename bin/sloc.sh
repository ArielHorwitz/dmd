#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Count source lines of code"
CLI=(
    --prefix "args_"
    -c "file-extensions;File extensions"
    -O "dir;Directory to search;.;d"
    -O "ignore-pattern;Regex patterns for lines to ignore;(^[[:space:]]*(#|//|--)|^$);i"
    -O "mode;Mode of operation: (t)otal, (f)iles, (s)how;total;m"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

find_extensions=(-false)
for ext in "${args_file_extensions[@]}"; do
    find_extensions+=(-o -name "*.$ext")
done
find_cmd=(find "$args_dir" -type f \( "${find_extensions[@]}" \))

case $args_mode in
    t | total )
        "${find_cmd[@]}" -exec cat {} + | grep -vE "$args_ignore_pattern" | wc -l
        ;;
    f | files )
        "${find_cmd[@]}" -print0 | xargs -0 -I {} sh -c \
            'echo "$(grep -cvE "$1" "$2") $2"' _ "$args_ignore_pattern" {}
        ;;
    s | show )
        "${find_cmd[@]}" -exec cat {} + | grep -vE "$args_ignore_pattern"
        ;;
    * )
        exit_error "Unknown mode of operation: $args_mode"
esac
