#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Must run $0 as root" >&2 && exit 1

[[ -n $1 ]] && LAYER=$1 || LAYER="base"

# Set layer state
mkdir --parents /var/opt/iukbtw
echo $LAYER | tee /var/opt/iukbtw/layer

# Set display gamma
case $LAYER in
    base ) /opt/iukbtw/bin/gamma;;
    text ) /opt/iukbtw/bin/gamma blue;;
esac
