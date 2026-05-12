#! /bin/bash

# Restore hardware and reset configuration in case something becomes unusable

# Restore keyboard
killall kmonad
# Restore monitors
hyprctl --instance 0 eval 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })'
hyprctl --instance 0 eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "auto" })'

# Restore lockscreen
hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'
sleep 0.2
hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'
