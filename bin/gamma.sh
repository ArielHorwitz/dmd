#! /bin/bash

H=1.0
M=0.9
L=0.7
case $1 in
    bright    ) gamma=$H:$H:$H ;;
    dark      ) gamma=$L:$L:$L ;;
    red       ) gamma=$H:$M:$M ;;
    green     ) gamma=$M:$H:$M ;;
    blue      ) gamma=$M:$M:$H ;;
    orange    ) gamma=$H:$M:$L ;;
    cyan      ) gamma=$L:$H:$M ;;
    purple    ) gamma=$M:$L:$H ;;
    *         ) gamma=1 ;;
esac

for monitor in $(xrandr -q | grep " connected" | awk '{print $1}') ; do
    xrandr --output $monitor --gamma $gamma
done
