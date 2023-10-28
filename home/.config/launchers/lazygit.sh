#! /bin/bash

set -m

alacritty -e lazygit &

sleep 0.3
iukmessenger scratch --move 8
iukmessenger scratch --show 8
xdotool getactivewindow windowsize --sync 1800 900
windowcenter
iukmessenger scratch --show 8

