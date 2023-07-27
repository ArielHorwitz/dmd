#!/bin/bash

set -e

[[ $EUID -eq 0 ]] && echo "Do not run $0 as root." && exit 1

title () { printf "\n█▓▒░ $1 ░▒▓█\n" ; }
subtitle () { printf "\n░▒▓█ $1\n" ; }


title "Installing iukbtw"

subtitle "Updating System"
[[ $(pacman -Q yay) ]] || sudo pacman --noconfirm -Syuq yay

# Install dependencies
if [[ $1 = "deps" ]]; then
    # Install packages
    subtitle "Installing dependencies"
    yay -Sq --needed --noconfirm - < ./root/opt/iukbtw/data/dependencies.txt
    # Install Python libraries
    subtitle "Installing Python libraries"
    python -m pip install --no-input --break-system-packages --user arrow httpx
fi


subtitle "Copying binaries"
recreatedir () {
    [[ -d $1 ]] && sudo rm --verbose -rf $1
    sudo mkdir --verbose --parents $1
}
OPTDIR=/opt/iukbtw
BINDIR=/opt/iukbtw/bin
USRBINDIR=/usr/bin/iukbtw
CONFDIR=/etc/opt/iukbtw
recreatedir $BINDIR
recreatedir $USRBINDIR
recreatedir $CONFDIR

# Copy non-user data
cd ./root && sudo cp --verbose --recursive ./ / && cd ..
sudo chmod +x --recursive $BINDIR

# Remove binary file extensions and symlink bin dir
for filename in "$BINDIR"/* ; do
    newname=$(echo $filename | rev | cut -d. -f2- | rev)
    [[ $filename != $newname ]] && sudo mv $filename $newname
    sudo cp --verbose --symbolic-link $newname $USRBINDIR
done

# Add iukenv sourcing to profile
USRPROF=$HOME/.profile
if [[ -f $USRPROF ]]; then
    # Remove export line if exists, for idempotency
    PROFILE_LINE=$(cat $USRPROF | grep -nm 1 "iuk" | cut -d: -f1)
    [[ -n $PROFILE_LINE ]] && sed -i $PROFILE_LINE"d" $USRPROF
fi
printf "[[ -f ~/.iukenv ]] && source ~/.iukenv\n" >> $USRPROF


# Configure
subtitle "Configuring $USER @ $HOME"
# Add sudoer rules -- check with visudo before copy!
sudo groupadd -f iukbtw && sudo usermod -aG iukbtw $USER
if [[ $(visudo -csf ./root/opt/iukbtw/data/sudoers | grep "parsed OK") = "" ]] ; then
    echo "Failed check on sudoer file"
    exit 1
else
    sudo cp --verbose --force ./root/opt/iukbtw/data/sudoers /etc/sudoers.d/50-iukbtw
fi
# Add udev rules for KMonad
# (https://github.com/kmonad/kmonad/issues/160#issuecomment-766121884)
sudo groupadd -f uinput && sudo usermod -aG uinput $USER
sudo usermod -aG input $USER
echo uinput | sudo tee /etc/modules-load.d/uinput.conf 1>/dev/null
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/90-uinput.rules 1>/dev/null


# Copy dotfiles
subtitle "Copying user home skeleton"
cd ./home && cp --verbose --recursive --parents ./ $HOME && cd ..


# Completion tasks
subtitle "Done."
[[
    -z $(groups | grep input) ||
    -z $(groups | grep uinput) ||
    -z $(groups | grep iukbtw)
]] && echo "Please login again for group config to apply."
[[ -z $(echo $PATH | grep $BINDIR) ]] && echo "Please login again for PATH to apply"
