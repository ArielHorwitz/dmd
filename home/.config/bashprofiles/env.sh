#! /bin/bash

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000

extra_paths_prepend=(
    "$HOME/.local/bin/testing"
)

extra_paths_append=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
~>>>
~>>> think
    "/snap/bin"
~<<<
)

export PATH=$(withpath ${extra_paths_append[@]})
export PATH=$(withpath -p ${extra_paths_prepend[@]})
