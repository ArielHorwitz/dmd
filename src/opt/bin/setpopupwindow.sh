#!/bin/bash

i3-msg "floating enable"
xdotool getactivewindow windowsize $1 $2
windowcenter
