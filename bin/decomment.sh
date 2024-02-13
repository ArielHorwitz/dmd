#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Remove comments and empty lines.

The <pattern> is used for 's///' in sed, so characters require escaping appropriately."
CLI=(
    -o "file;Input file (instead of stdin)"
    -O "pattern;Regex representing the start of a comment;#;p"
    -f "keep-empty;Do not remove empty lines;;k"
    -f "show-script;Print sed script instead of processing and exit;;s"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# Resolve input
input=$file
[[ -n $input ]] || input='-'

# Resolve script
script=""
[[ -n $keep_empty ]] || script+="/^\s*\$/d ; /^\s*$pattern.*\$/d ; "
script+="s/$pattern.*//g ; "

# Show script
[[ -z $show_script ]] || { echo $script; exit 0; }

# Execute sed
cat $input | sed -e "$script" || { echo "Script: $script"; exit 1; }

