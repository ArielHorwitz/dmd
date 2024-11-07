#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Run a suite of Python formatters and linters."
CLI=(
    --prefix "args_"
    -o "target;Target file or directory to operate on;."
    -O "line-length;Maximum line length;88"
    -f "clear;Clear the terminal before running;;c"
    -f "strict;Run MyPy in strict mode;;s"
    -f "warn;Warn on missing commands;;w"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ -n $args_clear ]]; then clear; fi

warn() {
    set -e
    if [[ $args_warn ]]; then
        printcolor -s warn "missing $1"
    fi
}

# Formatters
if command -v isort >/dev/null; then
    printcolor -fc "=== isort ==="
    isort --line-length $args_line_length --profile black $args_target
else
    warn "isort"
fi

if command -v black >/dev/null; then
    printcolor -fc "=== Black ==="
    black --check --line-length $args_line_length --fast $args_target
else
    warn "black"
fi

# Linters
if command -v mypy >/dev/null; then
    printcolor -fm "=== MyPy ==="
    mypy_args=(
        --exclude 'venv|.venv'
        `[[ -z $args_strict ]] || echo --strict`
    )
    mypy ${mypy_args[@]} $args_target
else
    warn "mypy"
fi

if command -v flake8 >/dev/null; then
    printcolor -fm "=== Flake8 ==="
    flake8 --max-line-length $args_line_length --extend-exclude 'venv,.venv' $args_target
else
    warn "flake8"
fi
