#! /bin/bash

[[ -n $BASHPROFILES_INIT_SOURCED ]] && return
export BASHPROFILES_INIT_SOURCED=1

append_path() {
    local new_path
    for new_path in "$@"; do
        if [[ ":$PATH:" != *:"$new_path":* ]]; then
            PATH="${PATH:+$PATH:}$new_path"
        fi
    done
}

prepend_path() {
    local new_path
    for new_path in "$@"; do
        if [[ ":$PATH:" != *:"$new_path":* ]]; then
            PATH="$new_path${PATH:+:$PATH}"
        fi
    done
}

export -f append_path
export -f prepend_path

umask 0022

source ~/.config/bashprofiles/env.sh
if [[ -f ~/.config/bashprofiles/devenv.sh ]]; then
    source ~/.config/bashprofiles/devenv.sh
fi
eval $(sshman) > /dev/null
