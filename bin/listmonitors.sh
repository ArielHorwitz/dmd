#! /bin/bash

xrandr --listactivemonitors | grep -P "^\s*\d+:\s" | while read -r line ; do
    [[ -z $line ]] && continue
    details=($line)
    monitor=${details[3]}
    echo $monitor
done
