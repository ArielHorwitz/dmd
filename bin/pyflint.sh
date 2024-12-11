#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Run a suite of Python formatters and linters."
CLI=(
    --prefix "args_"
    -o "target;Target file or directory to operate on;."
    -O "line-length;Maximum line length;88"
    -f "format;Run the formatters (not in check mode);;f"
    -f "clear;Clear the terminal before running;;c"
    -f "check-stubs;Ignore missing stubs in MyPy"
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
        printcolor -s warn "=== $1 missing ==="
    fi
}

isort_args=(
    --line-length $args_line_length
    --profile black
    $args_target
)
black_args=(
    --line-length $args_line_length
    --fast
    $args_target
)

if [[ $args_format ]]; then
    isort ${isort_args[@]}
    black ${black_args[@]}
    exit
fi

# Formatters
if command -v isort >/dev/null; then
    printcolor -fc "=== isort ==="
    isort --check ${isort_args[@]}
else
    warn "isort"
fi

if command -v black >/dev/null; then
    printcolor -fc "=== Black ==="
    black --check ${black_args[@]}
else
    warn "Black"
fi

# Linters
if command -v flake8 >/dev/null; then
    printcolor -fc "=== Flake8 ==="
    flake8 --max-line-length $args_line_length --extend-exclude 'venv,.venv' $args_target && printcolor -ob 'All good!'
else
    warn "Flake8"
fi

if command -v mypy >/dev/null; then
    printcolor -fc "=== MyPy ==="
    mypy_args=(
        --exclude 'venv|.venv'
        `[[ -z $args_strict ]] || echo --strict`
        `[[ -n $args_check_stubs ]] || echo --ignore-missing-imports`
    )
    mypy ${mypy_args[@]} $args_target
else
    warn "MyPy"
fi
