#! /usr/bin/bash

# shopt
shopt -s histappend
shopt -s expand_aliases
shopt -s checkwinsize  # https://tiswww.case.edu/php/chet/bash/FAQ (E11)

[[ $- = *i* ]] && source ~/.config/bashprofiles/color.sh
source ~/.config/bashprofiles/aliases.sh
source ~/.config/bashprofiles/style_exa.sh


# xhost +local:root > /dev/null 2>&1

