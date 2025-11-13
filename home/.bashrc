#! /bin/bash

source ~/.config/bashprofiles/init.sh

shopt -s histappend
shopt -s expand_aliases
shopt -s checkwinsize

source ~/.config/bashprofiles/aliases.sh
source ~/.config/bashprofiles/eza.sh
eval $(psprompt)
