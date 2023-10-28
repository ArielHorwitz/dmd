iuk log "Startup lembay"
xrandr --output HDMI-1 --primary
xrandr --output DP-2 --right-of HDMI-1
xrandr --output DP-2 --rotate left
i3-msg "workspace main; append_layout $HOME/.config/i3/main.json"
i3-msg "workspace aux; append_layout $HOME/.config/i3/aux.json"
i3-msg "workspace 9; append_layout $HOME/.config/i3/iuk.json"
sleep 200ms
alacritty --hold --title "iukdaemon" --command iukdaemon &
alacritty --hold --title "kmonad" --command kmdrun -l debug &
lite-xl &
alacritty --title "main1" &
alacritty --title "main2" &
alacritty --title "aux" &
sleep 200ms
$HOME/.config/launchers/lazygit.sh &
iuk log "Startup lembay complete"

