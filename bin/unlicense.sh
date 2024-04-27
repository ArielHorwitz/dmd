#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Release to the public domain using unlicense and commit."
CLI=(
    --prefix "args_"
    -f "rust-cargo;Add an appropriate entry in the Cargo.toml manifest file;;r"
    -f "git-commit;Commit changes in git;;g"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

curl -sSL "https://unlicense.org/UNLICENSE" -o UNLICENSE

if [[ -n $args_git_commit ]]; then
    sed -i '/^\[package\]$/a license = "Unlicense"' Cargo.toml
fi

if [[ -n $args_git_commit ]]; then
    git reset HEAD
    git add UNLICENSE
    if [[ -n $args_git_commit ]]; then
        git add Cargo.toml
    fi
    git commit -m "Release to the public domain"
    git status
fi
