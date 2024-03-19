#!/usr/bin/bash
set -e

FONTDIR="$HOME/.local/share/fonts/"
NERDFONTS="https://github.com/ryanoasis/nerd-fonts.git"
TMPDIR="/tmp/install_fonts"

install_font() {
    local name=$1
    local target=$2
    tcprint "debug]Installing font: $name -> $target"
    clonedir $NERDFONTS patched-fonts/$name $TMPDIR/$target --delete
    flattendir --force $TMPDIR/$target $FONTDIR/$target
    tcprint "ok]Installed: $target"
}

# FiraCode
install_font FiraCode firacode
# RobotoMono
install_font RobotoMono roboto
# DejaVuSansMono
install_font DejaVuSansMono dejavu
# DroidSansMono
install_font DroidSansMono droid

tcprint "notice]Installed fonts:"
fc-cache
fc-list | grep -E "\.local/.*(firacode|roboto|dejavu|droid)" | sort
