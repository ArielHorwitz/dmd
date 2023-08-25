#! /bin/bash

set -m

i3-msg split horizontal
alacritty --hold --option cursor.unfocused_hollow=false -e neofetch &
sleep 0.1
alacritty --hold --option cursor.unfocused_hollow=false -e curl https://wttr.in/moon?FQ &
sleep 0.1
alacritty --hold --option cursor.unfocused_hollow=false -e curl https://wttr.in/Rehovot?FQP1 &
sleep 0.3
i3-msg move down
i3-msg resize shrink height 100

