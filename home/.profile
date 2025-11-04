#! /bin/bash

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

umask 0022

source ~/.config/bashprofiles/env.sh
if [[ -f ~/.config/bashprofiles/devenv.sh ]]; then
    source ~/.config/bashprofiles/devenv.sh
fi
eval $(sshman) > /dev/null

[[ $- = *i* ]] && source ~/.bashrc
