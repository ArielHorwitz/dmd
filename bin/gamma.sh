#! /bin/bash

H=1.2
M=1
L=0.5
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

for monitor in $(listmonitors) ; do
    xrandr --output $monitor --gamma $gamma
done
