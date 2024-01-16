#! /bin/bash

xrandr -q | grep " connected" | cut -d' ' -f1
