#! /bin/bash

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000
# ~>>>
# ~>>> lembay
# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
# we rewrite the paths later, but these 2 lines provide environment variables
# and functions so we can't skip
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# ~<<<

# Path
PATH=""
paths_desc_priority=(
    # Personal
    "$HOME/.local/bin/testing"
    "$HOME/.local/bin"
    "/usr/bin/iukbtw"
    # Environments
    "$HOME/.cargo/bin"
    # ~>>>
    "$HOME/.pyenv/plugins/pyenv-virtualenv/shims"
    "$HOME/.pyenv/shims"
    "$HOME/.pyenv/bin"
    # ~>>> lemnos
    # ~<<<
    # System
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/bin"
    "/usr/bin/site_perl"
    "/usr/bin/vendor_perl"
    "/usr/bin/core_perl"
)
for path in "${paths_desc_priority[@]}"; do
    PATH="$PATH:$path"
done
[[ $PATH = :* ]] && PATH=${PATH:1}
export PATH
