#! /bin/bash

# Restore hardware and reset configuration in case something becomes unusable

# Restore keyboard
killall kmonad
# Restore monitors
hyprctl --instance 0 keyword monitor ",preferred,auto,auto"
hyprctl --instance 0 keyword monitor "eDP-1,preferred,auto,auto"

# Restore lockscreen
hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'
sleep 0.2
hyprctl --instance 0 'dispatch exec hyprlock'
