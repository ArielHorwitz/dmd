#! /bin/bash

i3-msg "workspace main; append_layout $HOME/.config/i3/main.json"
sleep 0.5
lite-xl & disown
alacritty --title "main1" & disown
alacritty --title "main2" & disown

