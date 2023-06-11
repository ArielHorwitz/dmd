#!/bin/bash

mkdir --parents "/home/$USER/temp/screen/"
scrot $@ -uf /home/$USER/temp/screen/%Y-%m-%d_%H:%M:%S.png -e "userprompt -p 'Screenshot name: ' -e 'mv \$f /home/$USER/temp/screen/%Y-%m-%d_%H:%M:%S_{{}}.png'"
