#! /bin/bash

SLEEPTIME=0.5

iuk log --reset
iuk log "iuk startup"

# iuk
iuk log "starting iuk daemon"
alacritty --title "iukdaemon" --command iukdaemon & disown
sleep $SLEEPTIME
iukmessenger scratch --move 7
iukmessenger scratch --show 7
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 1875 500 &&
xdotool getactivewindow windowmove --sync 25 25
iukmessenger scratch --show 7

iuk log "starting kmonad"
alacritty --title "kmonad" --command kmdrun & disown
sleep $SLEEPTIME
iukmessenger scratch --move 7
iukmessenger scratch --show 7
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 1875 500 &&
xdotool getactivewindow windowmove --sync 25 550
iukmessenger scratch --show 7

iuk log "starting lazygit"
alacritty --title "lazygit" --command lazygit & disown
sleep $SLEEPTIME
iukmessenger scratch --move 8
iukmessenger scratch --show 8
sleep $SLEEPTIME
xdotool getactivewindow windowsize --sync 1850 1000
windowcenter
iukmessenger scratch --show 8


iuk log "Lembay layout"
$HOME/.config/launchers/lembay.sh

iuk log "configuring displays"
~/.config/launchers/displays.sh
~/.config/launchers/polybar.sh

iuk log "iuk startup complete"

