#! /bin/bash

set -e

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="Wrapper for exa with personal defaults"
# Argument syntax: "<arg_name>;<help_text>;<default_value>;<short_name>"
CLI=(
    -o "dir;Target directory"
    -O "depth;Recursion depth;;d"
    -f "recursive;Recursively list directories;;r"
    -O "sort;Sorting;;s"
    -O "reverse;Reverse sorting (overrides --sort);;S"
    -f "hide;Hide hidden files;;H"
    -f "nogit;Don't show git status and show gitignored files;;g"
    -f "header;Show header"
    -f "nographics;Do not use color and graphics;;n"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

CONSTANT_ARGS="--long --group-directories-first"
HIDDEN="--all"
GRAPHICS="--color=always --icons"

[[ -z $hide ]] || HIDDEN=""
[[ -z $recursive ]] || RECURSE="--tree"
[[ -z $depth ]] || LEVEL="--level $depth"
[[ -z $sort ]] || SORT="--sort $sort"
[[ -z $reverse ]] || SORT="--reverse --sort $reverse"
[[ -n $nogit ]] || GIT="--git-ignore --git"


[[ -z $header ]] || HEADER="--header"
if [[ -n $nographics ]]; then
    GRAPHICS="--color=never --no-icons"
    [[ $RECURSE != "--tree" ]] || RECURSE="--recurse"
fi

exa $CONSTANT_ARGS $HIDDEN $RECURSE $LEVEL $SORT $GIT $GRAPHICS $HEADER $dir

