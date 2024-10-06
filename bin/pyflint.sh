#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Run a suite of Python formatters and linters."
CLI=(
    --prefix "args_"
    -o "target;Target file or directory to operate on;."
    -O "line-length;Maximum line length;88"
    -f "clear;Clear the terminal before running;c"
    -f "strict;Run MyPy in strict mode;s"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ -n $args_clear ]]; then clear; fi

# Formatters
printcolor -fc "=== isort ==="
isort --line-length $args_line_length --profile black $args_target

printcolor -fc "=== Black ==="
black --line-length $args_line_length --fast $args_target

# Linters
printcolor -fm "=== MyPy ==="
mypy_args=(
    --exclude 'venv|.venv'
    `[[ -z $args_strict ]] || echo --strict`
)
mypy ${mypy_args[@]} $args_target

printcolor -fm "=== Flake8 ==="
flake8 --max-line-length $args_line_length --extend-exclude 'venv,.venv' $args_target
