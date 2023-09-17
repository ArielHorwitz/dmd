#!/usr/bin/bash

DATADIR="$(pathparent $BASH_SOURCE $PWD --resolve)/"
sudo echo "Root privileges aquired."

set -e

TMPDIR="/tmp/install-lite-xl/"
echo "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

# Download Lite XL v2.1.1
echo "Downloading..."
URL="https://github.com/lite-xl/lite-xl/releases/download/v2.1.1/lite-xl-v2.1.1-addons-linux-x86_64-portable.tar.gz"
echo "  $URL"
wget -q --output-document "lite-xl.tar.gz" $URL

echo "Extracting..."
tar -xzf "lite-xl.tar.gz"
cd lite-xl

echo "Deleting existing plugins..."
rm -rf $HOME/.local/share/lite-xl

if [[ $1 = "--fresh" ]]; then
    echo "Deleting existing config..."
    rm -rf $HOME/.config/lite-xl/
fi

echo "Copying files..."
# Copy binary
mkdir -p $HOME/.local/bin
mv -f lite-xl $HOME/.local/bin/
chmod +x $HOME/.local/bin/lite-xl

# Copy core and addons
mkdir -p $HOME/.local/share/lite-xl
mv -f data/* $HOME/.local/share/lite-xl/

set +e

# XDG menus
DESKTOP_APPS="$HOME/.local/share/applications/"
DESKTOP_ICONS="$HOME/.local/share/icons/hicolor/48x48/apps/"
mkdir -p $DESKTOP_APPS
mkdir -p $DESKTOP_ICONS
[[ -f $DATADIR/lite-xl.desktop ]] && cp -f $DATADIR/lite-xl.desktop $DESKTOP_APPS
[[ -f $DATADIR/lite-xl.png ]] && cp -f $DATADIR/lite-xl.png $DESKTOP_ICONS
xdg-desktop-menu forceupdate

# Plugin Manager (lpm)
echo "Installing lpm plugin manager..."
URL="https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux"
wget -q $URL -O $HOME/.local/bin/lpm
chmod +x $HOME/.local/bin/lpm

# Plugins
echo "Installing plugins..."
lpm install --quiet --assume-yes autoinsert bracketmatch wordcount

# LSP
echo "Installing LSP..."
mkdir -p $HOME/.config/lite-xl/
cd $HOME/.config/lite-xl/
git clone -q https://github.com/lite-xl/lite-xl-lsp plugins/lsp
git clone -q https://github.com/lite-xl/lite-xl-widgets libraries/widget
git clone -q https://github.com/liquidev/lintplus plugins/lintplus
wget -q https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/snippets.lua -O plugins/snippets.lua
wget -q https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/lsp_snippets.lua -O plugins/lsp_snippets.lua

echo "Installing Python LSP..."
python -m pip install -q --break-system-packages python-lsp-server

echo "Installing Rust LSP..."
rustup component add rust-analyzer

echo "Installing Lua LSP..."
sudo pacman -Sq --needed --noconfirm lua-language-server

echo "Installing Bash LSP..."
sudo npm install --silent --no-progress --global bash-language-server

echo "Installing Dockerfile LSP..."
sudo npm install --silent --no-progress --global dockerfile-language-server-nodejs

echo "Cleaning up temporary working directory $TMPDIR"
rm -rf $TMPDIR

