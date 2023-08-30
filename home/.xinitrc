#! /bin/bash

# Mount disks
mount -a

# Set power management / lockscreen
xset -dpms s 7200

# Start WM
exec i3

