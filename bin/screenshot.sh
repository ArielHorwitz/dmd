#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Take a screenshot"
CLI=(
    --prefix "args_"
    -f "desktop;Capture the entire desktop, not just focused window;;d"
    -f "prompt;Prompt for screenshot name (overrides --name);;p"
    -O "name;Screenshot name;;n"
    -O "targetdir;Target directory to save to;$HOME/temp/screen;t"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

temp_file="$(mktemp --dry-run).png"
timestamp=$(timestamp)

grim_args=()
if [[ -z $args_desktop ]]; then
    region=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    grim_args+=(-g "$region")
fi
# Take screenshot
grim "${grim_args[@]}" "$temp_file"

# Get file path and name
if [[ $args_prompt ]]; then
    name=$(terminalprompt 'Screenshot name: ')
else
    name=$args_name
fi
target_file="${args_targetdir}/${timestamp}${name:+_$name}.png"
# Move file
mkdir --parents "$args_targetdir"
mv "$temp_file" "$target_file"
