#! /bin/bash
set -e

module_name="$1"
source_dir="${2:-.}"

if [[ -z $module_name ]]; then
    echo "Usage: $(basename "$0") <module_name> [source_dir]" >&2
    exit 1
fi

source_dir=$(realpath "$source_dir")

echo "Searching for import of '$module_name' in '$source_dir'" >&2

div="([[:space:]]|\.)"
module_term="${div}${module_name}${div}"
expression="import.*${module_term}|from.*${module_term}"

grep --color=always -Er "$expression" "$source_dir"
