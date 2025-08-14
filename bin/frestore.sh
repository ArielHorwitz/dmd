#! /bin/bash

# Restore hardware and reset configuration in case something becomes unusable

# Restore keyboard
killall kmonad
# Restore monitors
hyprctl keyword monitor ",preferred,auto,auto"
hyprctl keyword monitor "eDP-1,preferred,auto,auto"
