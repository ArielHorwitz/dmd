#! /bin/bash

N=1
H=0.9
M=0.75
L=0.6
gamma="1"
case $1 in
    red       ) gamma=$N:$M:$M ;;
    green     ) gamma=$M:$N:$M ;;
    blue      ) gamma=$M:$M:$N ;;
    orange    ) gamma=$N:$H:$L ;;
    cyan      ) gamma=$L:$H:$N ;;
    purple    ) gamma=$H:$L:$N ;;
esac

for monitor in $(listmonitors) ; do
    xrandr --output $monitor --gamma $gamma
done
