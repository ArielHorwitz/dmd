#!/usr/bin/bash

FONTDIR="$HOME/.local/share/fonts/"
NERDFONTS="https://github.com/ryanoasis/nerd-fonts.git"

# FiraCode
clonedir $NERDFONTS patched-fonts/FiraCode $FONTDIR/firacode/ --delete
flattendir $FONTDIR/firacode/ --clean

# RobotoMono
clonedir $NERDFONTS patched-fonts/RobotoMono $FONTDIR/roboto/ --delete
flattendir $FONTDIR/roboto/ --clean

# DejaVuSansMono
clonedir $NERDFONTS patched-fonts/DejaVuSansMono $FONTDIR/dejavu/ --delete
flattendir $FONTDIR/dejavu/ --clean

# DroidSansMono
clonedir $NERDFONTS patched-fonts/DroidSansMono $FONTDIR/droid/ --delete
flattendir $FONTDIR/droid/ --clean


fc-cache
fc-list | grep -E "\.local/.*(firacode|roboto|dejavu|droid)" | sort

