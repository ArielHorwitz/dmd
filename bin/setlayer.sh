#!/bin/bash

layer=$1
keyboard_layout=$2

if [[ $layer = "base" ]]; then
    setxkbmap us
elif [[ $layer = "text" ]]; then
    setxkbmap $keyboard_layout
else
    echo "No such layer '$layer'" >&2; exit 1
fi
