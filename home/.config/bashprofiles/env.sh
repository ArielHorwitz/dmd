#! /bin/bash

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000

# Path
paths_descending_priority=(
    # Personal
    "$HOME/.local/bin/testing"
    "$HOME/.local/bin"
    "/usr/bin/iukbtw"
    # Environments
    "$HOME/.cargo/bin"
    # System
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/bin"
    "/usr/bin/site_perl"
    "/usr/bin/vendor_perl"
    "/usr/bin/core_perl"
)
PATH=""
for path in "${paths_descending_priority[@]}"; do
    PATH+=":$path"
done
[[ $PATH = :* ]] && PATH=${PATH:1}
export PATH
