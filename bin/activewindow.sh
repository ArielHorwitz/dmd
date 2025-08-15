#! /bin/bash
set -e

NOTIFICATION_ICON="/usr/share/icons/dmd/monitor.svg"

window_details=$(hyprctl -j activewindow)

echo "$window_details"

title=$(echo "$window_details" | jq -r '.title')
class=$(echo "$window_details" | jq -r '.class')
initial_title=$(echo "$window_details" | jq -r '.initialTitle')
initial_class=$(echo "$window_details" | jq -r '.initialClass')
pid=$(echo "$window_details" | jq -r '.pid')
xwayland=$(echo "$window_details" | jq -r '.xwayland')

output_title="Active window"
output_text="        <u>Title:</u> $title
<u>Initial title:</u> $initial_title
        <u>Class:</u> $class
<u>Initial class:</u> $initial_class
          <u>PID:</u> $pid
     <u>xwayland:</u> $xwayland"

notify_args=(
    -t 5000
    -i "$NOTIFICATION_ICON"
    -h string:synchronous:activewindowinfo
)
notify-send "${notify_args[@]}" "$output_title" "$output_text"
