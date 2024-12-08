#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Take a screenshot"
CLI=(
    --prefix "args_"
    -f "desktop;Capture the entire desktop, not just focused window;;d"
    -f "prompt;Prompt for screenshot name;;p"
    -O "name;Screenshot name;;n"
    -O "targetdir;Target directory to save to;$HOME/temp/screen;t"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

temp_file="$(mktemp --dry-run).png"
timestamp=$(timestamp)

scrot_args=(--file $temp_file)
[[ $args_desktop ]] || scrot_args+=(--focused)
# Take screenshot
scrot ${scrot_args[@]}

# Get file path and name
[[ $args_prompt ]] && name=$(terminalprompt 'Screenshot name: ') || name=$args_name
target_file="${args_targetdir}/${timestamp}${name:+_$name}.png"
# Move file
mkdir --parents $args_targetdir
mv $temp_file $target_file
