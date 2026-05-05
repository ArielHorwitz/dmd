#! /bin/bash

_restart_app() {
    local app name
    app=$1
    name=${2:-$app}
    killall "$name" || :
    sleep 0.1
    "$app" & disown
}

_restart_app waybar
_restart_app hypridle
_restart_app hyprsunset
_restart_app hyprpaper

hyprctl dispatch forcerendererreload || :

killall dunst || :
kmdrun

clipcatd --replace
