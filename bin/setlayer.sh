#!/bin/bash

polyhook() {
    polybar-msg action kmd hook $1
}

case $1 in
    base ) polyhook 0; setxkbmap us; gamma ;;
    text ) polyhook 1; setxkbmap $2; gamma cyan ;;
    *    ) echo "No such layer $1" ;;
esac
