#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Run a python script within a virtual environment."
CLI=(
    --prefix "args_"
    -p "source;Source code directory"
    -o "script;Name of file to run;main.py"
    -O "venv;Name of virtual environment directory;venv;V"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

cd "$args_source"
source "$args_venv/bin/activate"
python "$args_script"
