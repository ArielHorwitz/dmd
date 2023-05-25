#!/bin/bash

eval `xdotool getwindowgeometry --shell $(xdotool getwindowfocus)`
xdotool mousemove `expr $X + 1` `expr $Y + $HEIGHT - 1`
