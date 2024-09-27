#! /bin/bash
set -e

# TODO: use json output to format different modes

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Check for trailing whitespace.

Display modes: check, json, numbers, lines, files, count.

In 'check' mode, return non-zero exit code if whitespace was found."
CLI=(
    --prefix "args_"
    -c "file;File(s) to check"
    -f "no-hidden;Do not search hidden files"
    -O "mode;Display mode;lines;m"
    -e "ripgrep_args;Extra arguments for ripgrep"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

ripgrep_args=()
[[ $args_no_hidden ]] || ripgrep_args+=(--hidden)

case $args_mode in
    check   )   ripgrep_args+=(--quiet) ;;
    json    )   ripgrep_args+=(--json) ;;
    numbers )   ripgrep_args+=(--line-number --only-matching) ;;
    lines   )   ripgrep_args+=(--line-number) ;;
    files   )   ripgrep_args+=(--files-with-matches) ;;
    count   )   ripgrep_args+=(--files-with-matches --count) ;;
    *       )   exit_error "Invalid mode: '$args_mode'"
esac

rg ${ripgrep_args[@]} ${args_ripgrep_args[@]} '\s+$' ${args_file[@]}
