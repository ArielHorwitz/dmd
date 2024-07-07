#! /bin/bash

export PAGER=bat
export VISUAL=pragtical
export EDITOR=pragtical
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000

extra_paths=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.local/bin/testing"
~>>>
~>>> think
    "/snap/bin"
~<<<
)

export PATH=$(withpath ${extra_paths[@]})
