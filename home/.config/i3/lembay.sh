#! /bin/bash

iuk log "Lembay startup"
xrandr --output HDMI-1 --primary
xrandr --output DP-2 --right-of HDMI-1
xrandr --output DP-2 --rotate left
i3-msg "workspace aux; append_layout $HOME/.config/i3/aux.json"
i3-msg "workspace main; append_layout $HOME/.config/i3/main.json"
sleep 0.5
lite-xl &
alacritty --title "main1" &
alacritty --title "main2" &
alacritty --title "aux" &
iuk log "Lembay startup complete"

