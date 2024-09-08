#! /bin/bash

# [[ $- = *i* ]] && interactive_terminal_setup || return

shopt -s histappend
shopt -s expand_aliases
shopt -s checkwinsize  # https://tiswww.case.edu/php/chet/bash/FAQ (E11)

umask 0002

# Environment
source ~/.config/bashprofiles/env.sh
source ~/.config/bashprofiles/aliases.sh
if [[ -f ~/.config/bashprofiles/devenv.sh ]]; then
    source ~/.config/bashprofiles/devenv.sh
fi

# Colors and styles
source ~/.config/bashprofiles/exa.sh
eval $(psprompt)
