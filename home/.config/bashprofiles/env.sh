#! /bin/bash

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000
~>>>
~>>> zen
export QT_SCALE_FACTOR=2.0
~<<<

extra_paths_prepend=(
    "$HOME/.local/bin/testing"
    "$HOME/.cargo/bin"
)

extra_paths_append=(
    "$HOME/.local/bin"
)

export PATH=$(withpath ${extra_paths_append[@]})
export PATH=$(withpath -p ${extra_paths_prepend[@]})
