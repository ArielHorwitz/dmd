#! /bin/bash

export PATH=/usr/bin/iukbtw:$HOME/.local/bin:$PATH

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl

export HISTSIZE=10000
export HISTFILESIZE=100000
export COMMAND_PROMPT="history -a; history -c; history -r; $COMMAND_PROMPT"


. "$HOME/.cargo/env"

