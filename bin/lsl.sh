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
    -e "extra_eza_args;Extra args to pass to eza"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


eza_args=(--long --group-directories-first)

[[ -n $hide ]] || eza_args+=(--all)
[[ -z $header ]] || eza_args+=(--header)
[[ -z $depth ]] || eza_args+=(--level $depth)
[[ -z $sort ]] || eza_args+=(--sort $sort)
[[ -z $reverse ]] || eza_args+=(--reverse --sort $reverse)
[[ -z $git ]] || eza_args+=(--git-ignore --git --ignore-glob .git)
[[ -n $nographics ]] && eza_args+=(--color=never) || eza_args+=(--color=always)
if [[ -n $recursive ]]; then
    [[ -n $nographics ]] && eza_args+=(--recurse) || eza_args+=(--tree)
fi

eza_args+=(${extra_eza_args[@]})
eza_args+=("${file[@]}")

if [[ -n $nopaging ]]; then
    eza ${eza_args[@]}
else
    eza ${eza_args[@]} | bat -p
fi
