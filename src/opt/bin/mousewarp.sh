#!/bin/bash

eval `xdotool getwindowgeometry --shell $(xdotool getactivewindow)`

xdotool mousemove `expr $X + $WIDTH - 1` `expr $Y + $HEIGHT / 2 `
