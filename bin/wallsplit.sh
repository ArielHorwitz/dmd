#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Split an image horizontally."
CLI=(
    --prefix "args_"
    -p "input-file;Input file"
    -O "split-count;Split the image into a number of times;2;c"
    -O "output-file;Output file (overrides other output path arguments);;o"
    -O "output-ext;Output file extensions;png;e"
    -O "output-dir;Output directory;.;O"
    -O "output-suffix;Suffix to add to output files;-split;S"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_output_file ]]; then
    output_path=$args_output_file
else
    input_name=$(basename "$args_input_file")
    output_path="${args_output_dir}/${input_name%.*}${args_output_suffix}.${args_output_ext}"
fi

horiz_percent=$(awk "BEGIN {print 100 / $args_split_count}")
magick "$args_input_file" -crop "${horiz_percent}%x100%" +repage "$output_path"
