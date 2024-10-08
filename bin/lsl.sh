#! /bin/bash

set -e

APP_NAME=$(basename "$0")
ABOUT="Wrapper for eza with personal defaults.

Valid sort fields:
    name, Name, extension, Extension, size, type, modified, accessed, created,
    inode, and none.
"
CLI=(
    -c "file;Display information about the files"
    -O "depth;Recursion depth;;d"
    -f "recursive;Recursively list directories;;r"
    -O "sort;Sorting;;s"
    -O "reverse;Reverse sorting (overrides --sort);;S"
    -f "hide;Hide hidden files;;H"
    -f "git;Show git status and hide gitignored files;;g"
    -f "header;Show header"
    -f "nographics;Do not use color and graphics;;n"
    -f "nopaging;Do not use paging;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

CONSTANT_ARGS="--long --group-directories-first"
HIDDEN="--all"
GRAPHICS="--color=always"

[[ -z $hide ]] || HIDDEN=""
[[ -z $recursive ]] || RECURSE="--tree"
[[ -z $depth ]] || LEVEL="--level $depth"
[[ -z $sort ]] || SORT="--sort $sort"
[[ -z $reverse ]] || SORT="--reverse --sort $reverse"
[[ -z $git ]] || GIT="--git-ignore --git --ignore-glob .git"


[[ -z $header ]] || HEADER="--header"
if [[ -n $nographics ]]; then
    GRAPHICS="--color=never"
    [[ $RECURSE != "--tree" ]] || RECURSE="--recurse"
fi

eza_command="eza $CONSTANT_ARGS $HIDDEN $RECURSE $LEVEL $SORT $GIT $GRAPHICS $HEADER ${file[@]}"

if [[ -n $nopaging ]]; then
    eval "$eza_command"
else
    eval "$eza_command" | bat -p
fi

