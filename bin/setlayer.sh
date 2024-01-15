#!/bin/bash

setlayer() {
    polybar-msg action kmd hook $1
    gamma $2
}

case $1 in
    base ) setlayer 0; setxkbmap us ;;
    text ) setlayer 1 cyan ;;
    *    ) echo "No such layer $1" ;;
esac
