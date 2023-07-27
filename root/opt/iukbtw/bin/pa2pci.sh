#!/bin/bash

pacmd set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo

pacmd list-sink-inputs | grep index | while read line
do
pacmd move-sink-input `echo $line | cut -f2 -d' '` alsa_output.pci-0000_00_1f.3.analog-stereo
done
