#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Must run $0 as root" >&2 && exit 1

[[ -n $1 ]] && LAYER=$1 || LAYER="base"

# Set layer state
mkdir --parents /var/iukbtw
echo $LAYER | tee /var/iukbtw/layer

# Set display gamma
case $LAYER in
    base ) /usr/bin/iukbtw/gamma;;
    text ) /usr/bin/iukbtw/gamma blue;;
esac
