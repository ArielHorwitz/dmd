#! /bin/bash
set -e

DATADIR=$PWD/`dirname "$0"`
REPO="kmonad/kmonad"

# Root
[[ $EUID -eq 0 ]] && exit_error "Do not run `basename $0` as root."
sudo -v

# Download and install latest KMonad
gh-download -t /bin $REPO

printcolor -s ok "Configuring udev rules and uinput module..."
# Add udev rules for KMonad
# (https://github.com/kmonad/kmonad/blob/master/doc/faq.md#q-how-do-i-get-uinput-permissions)
# (https://github.com/kmonad/kmonad/issues/160#issuecomment-766121884)
sudo groupadd -f uinput
sudo usermod -aG input,uinput $USER
local rules='KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"'
echo $rules | sudo tee /etc/udev/rules.d/90-uinput.rules >/dev/null
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
newgrp uinput
newgrp input

printcolor -s ok "Installed"
