#!/bin/bash

eval `xdotool getwindowgeometry --shell $(xdotool getactivewindow)`
xdotool mousemove `expr $X + 1` `expr $Y + $HEIGHT - 1`
