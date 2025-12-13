#! /bin/bash
set -e

BACON_CONFIG='
default_job = "lint"
summary = false

[jobs.lint]
command = ["./scripts/ruffer.sh"]
need_stdout = true
watch = [
    "pyproject.toml",
    "uv.lock",
    ".python-version",
    ".gitignore",
    "./src",
]

[jobs.format]
command = ["./scripts/ruffer.sh", "fix", "--no-lint"]
need_stdout = true
on_success = "back"
'

printerr() { printf '\x1b[1;31m%s\x1b[m\n' "$@" ; }
printok() { printf '\x1b[1;32m%s\x1b[m\n' "$@" ; }
try_command() {
    set -e
    local name=$1
    shift
    if "$@" ; then
        printok " ✔ $name"
        return 0
    else
        printerr " ✘ $name"
        return 1
    fi
}

format_check() {
    ruff check --select I "$@"
    ruff format --check "$@"
}

write_bacon_config() {
    for path in "$@"; do
        local target="${path}/bacon.toml"
        if [[ -f "$target" ]]; then
            printerr "Error: $target already exists"
            exit 1
        fi
        mkdir -p "$path"
        printf '%s' "$BACON_CONFIG" > "$target"
        printok "Created $target"
    done
}

show_help() {
    printf "Usage: %s [MODE] [OPTIONS] [-- PATH...]\n" "$0"
    printf "\nModes:\n"
    printf "  (c)heck          Check linting and formatting (default)\n"
    printf "  (f)ix            Apply linting and formatting fixes\n"
    printf "  (b)acon          Write bacon.toml configuration\n"
    printf "\nOptions:\n"
    printf "  --no-lint         Skip linting checks/fixes\n"
    printf "  --no-format       Skip formatting checks/fixes\n"
    printf "  -h, --help        Show this help message\n"
    printf "  --                Specify paths (default: current directory)\n"
}

MODE="check"
DO_LINT=1
DO_FORMAT=1
PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        c | check)        MODE="check"; shift ;;
        f | fix)          MODE="fix"; shift ;;
        b | bacon)        MODE="bacon"; shift ;;
        --no-lint)        DO_LINT=0; shift ;;
        --no-format)      DO_FORMAT=0; shift ;;
        -h | --help)      show_help; exit 0 ;;
        --)               shift; PATHS+=("$@"); break ;;
        *)                printerr "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ ${#PATHS[@]} -eq 0 ]]; then
    PATHS=(".")
fi

case "$MODE" in
    check)
        if [[ $DO_LINT -eq 1 ]]; then
            try_command "Lint" uvx ruff check "${PATHS[@]}"
        fi
        if [[ $DO_FORMAT -eq 1 ]]; then
            try_command "Formatting" format_check "${PATHS[@]}"
        fi
        ;;
    fix)
        if [[ $DO_LINT -eq 1 ]]; then
            uvx ruff check --fix "${PATHS[@]}"
        fi
        if [[ $DO_FORMAT -eq 1 ]]; then
            ruff check --select I --fix "${PATHS[@]}"
            ruff format "${PATHS[@]}"
        fi
        ;;
    bacon)
        write_bacon_config "${PATHS[@]}"
        ;;
esac
