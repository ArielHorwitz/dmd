#! /bin/bash

printcolor -s info "waybar"
killall -SIGUSR2 waybar
printcolor -s info "hyprland"
hyprctl dispatch forcerendererreload
printcolor -s info "dunst"
killall dunst
printcolor -s info "kmd"
kmdrun
