#!/bin/bash

window=$(xdotool getwindowfocus)
eval `xdotool getwindowgeometry --shell $window`
xdotool mousemove -window $window `expr $WIDTH / 2` `expr $HEIGHT / 2`
