#! /bin/bash

# Restore hardware and reset configuration in case something becomes unusable

# Restore keyboard
killall kmonad
# Restore monitors
hyprctl keyword monitor ",preferred,0x0,1.0"
