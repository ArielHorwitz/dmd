#! /bin/bash

SLEEPTIME=0.2

iuk log -r "Startup"

# iuk
alacritty --title "iukdaemon" --command iukdaemon &
sleep $SLEEPTIME
iukmessenger scratch --move 7
iukmessenger scratch --show 7
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 800 900
xdotool getactivewindow windowmove --sync 25 25
iukmessenger scratch --show 7

# kmd
alacritty --title "kmonad" --command kmdrun &
sleep $SLEEPTIME
iukmessenger scratch --move 7
iukmessenger scratch --show 7
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 800 900
xdotool getactivewindow windowmove --sync 850 25
iukmessenger scratch --show 7

# lazygit
alacritty -e lazygit &
sleep $SLEEPTIME
iukmessenger scratch --move 8
iukmessenger scratch --show 8
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 1800 900
windowcenter
iukmessenger scratch --show 8


$HOME/.config/i3/lembay.sh

