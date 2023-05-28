#!/bin/bash

set -e


[[ $EUID -eq 0 ]] && echo "Do not run $0 as root." && exit 1


title () { printf "\n░▒▓█ $1 \n" ; }
subtitle () { printf "\n■► $1\n" ; }
recreatedir () {
    [[ -d $1 ]] && sudo rm -rf $1
    sudo mkdir --parents $1
}

title "Installing iukbtw"

BINDIR=/opt/iukbtw/bin
USRBINDIR=/usr/bin/iukbtw
CONFDIR=/etc/opt/iukbtw
recreatedir $BINDIR
recreatedir $USRBINDIR
recreatedir $CONFDIR

# Copy scripts
ls -1 ./scripts/ | while read filename ; do
    targetfile=$(echo $filename| cut -d. -f1)
    sudo cp ./scripts/$filename $BINDIR/$targetfile
    sudo chmod +x $BINDIR/$targetfile
    sudo cp -s $BINDIR/$targetfile $USRBINDIR
done
# Add bin dir to PATH
USRPROF=$HOME/.profile
[[ -f $USRPROF ]]
sed -e $(cat $HOME/.profile | grep iuk -n | cut -d: -f1)d $USRPROF
printf "\nexport PATH=$BINDIR:\$PATH  # Add iukbtw commands to PATH\b" >> $USRPROF
# Copy config
sudo cp --recursive ./config/* $CONFDIR


if [[ $1 != "nodeps" ]]; then
    # Install dependencies
    subtitle "Installing dependencies"
    yay -S --needed --noconfirm - < ./deps.txt
    # Install Python libraries
    subtitle "Installing Python libraries"
    python -m pip install arrow
    python -m pip install requests
fi


# Configure
subtitle "Configuring for $USER @ $HOME"
# Add sudoer rule for /opt/iukbtw -- check with visudo before copy!
sudo groupadd -f iukbtw && sudo usermod -aG iukbtw $USER
if [[ $(visudo -csf ./sudoers | grep "parsed OK") = "" ]] ; then
    echo "Failed check on sudoer file"
    exit 1
else
    sudo cp --force ./sudoers /etc/sudoers.d/50-iukbtw
fi
# Add udev rules for KMonad
# (https://github.com/kmonad/kmonad/issues/160#issuecomment-766121884)
sudo groupadd -f uinput && sudo usermod -aG uinput $USER
sudo usermod -aG input $USER
echo uinput | sudo tee /etc/modules-load.d/uinput.conf
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/90-uinput.rules


# Copy dotfiles
subtitle "Copying user home skeleton"
cd ./skel && cp --recursive --parents ./ $HOME && cd ..


# Completion tasks
subtitle "Done."
[[
    -z $(groups | grep input) ||
    -z $(groups | grep uinput) ||
    -z $(groups | grep iukbtw)
]] && echo "Please login again for group config to apply."
[[ -z $(echo $PATH | grep $USRBINDIR) ]] && echo "Please login again for PATH to apply"
