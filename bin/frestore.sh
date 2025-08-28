#! /bin/bash

# Restore hardware and reset configuration in case something becomes unusable

# Restore keyboard
killall kmonad
# Restore monitors
hyprctl --instance 0 keyword monitor ",preferred,auto,auto"
hyprctl --instance 0 keyword monitor "eDP-1,preferred,auto,auto"
