#! /bin/bash

set -m

alacritty -e lazygit &

sleep 0.3
scratchpad --move 8
scratchpad --show 8
xdotool getactivewindow windowsize --sync 1800 900
windowcenter
scratchpad --show 8

