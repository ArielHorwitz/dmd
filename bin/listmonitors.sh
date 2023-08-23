#! /bin/bash

output=$(mons | grep "(enabled)")
printf "$output\n" | while read -r line ; do
    details=($line)
    monitor=${details[1]}
    echo $monitor
done
