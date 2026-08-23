#! /bin/bash
set -eo pipefail

APP_NAME=$(basename "${0%.*}")
ABOUT="Render a markdown file to a standalone HTML page and open it in the browser."
CLI=(
    --prefix "args_"
    -p "file;Markdown file to render"
    -O "open-with;Command to open the HTML with;xdg-open;o"
    -O "style;Stylesheet name from the config dir (defaults to the config file, else github);;s"
    -f "unsafe;Render raw inline HTML (pass --unsafe to comrak);;u"
    -f "unique;Write to a unique temp file instead of overwriting a single shared one;;U"
    -f "print-path;Print the HTML path instead of opening it;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -f $args_file ]] || exit_error "File not found: $args_file"

style_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$APP_NAME"
default_style_file="$style_dir/default-style"

style="$args_style"
if [[ -z $style && -f $default_style_file ]]; then
    read -r style < "$default_style_file" || true
fi
[[ -n $style ]] || style="github"

style_file="$style_dir/$style.css"
[[ -f $style_file ]] || exit_error "Stylesheet not found: $style_file (available: $(cd "$style_dir" && printf '%s ' *.css))"

comrak_args=(--gfm)
[[ -z $args_unsafe ]] || comrak_args+=(--unsafe)

title=$(basename "$args_file")
if [[ $args_unique ]]; then
    temp_file=$(mktemp --suffix=.html "${XDG_RUNTIME_DIR:-/tmp}/$APP_NAME.XXXXXX")
else
    temp_file="${XDG_RUNTIME_DIR:-/tmp}/$APP_NAME.html"
fi

{
    printf '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
    printf '<meta charset="utf-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    printf '<title>%s</title>\n' "$title"
    printf '<style>\n'
    cat "$style_file"
    printf '</style>\n</head>\n<body>\n<main class="markdown-body">\n'
    # Tag block-level elements with dir="auto" so the browser derives base
    # direction per block from its content (resolves to LTR for LTR text).
    comrak "${comrak_args[@]}" "$args_file" \
        | sed -E 's/<(p|li|h[1-6]|blockquote|th|td)>/<\1 dir="auto">/g'
    printf '</main>\n</body>\n</html>\n'
} >"$temp_file"

if [[ $args_print_path ]]; then
    printf '%s\n' "$temp_file"
else
    $args_open_with "$temp_file" >/dev/null 2>&1 &
fi
