#!/usr/bin/bash

set -e

TMPDIR="/tmp/install-lite-xl/"
echo "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

# Lite XL v2.1.1
echo "Downloading..."
URL="https://github.com/lite-xl/lite-xl/releases/download/v2.1.1/lite-xl-v2.1.1-addons-linux-x86_64-portable.tar.gz"
echo "  $URL"
wget --no-verbose --output-document "lite-xl.tar.gz" $URL

echo "Extracting..."
tar -xzf "lite-xl.tar.gz"
cd lite-xl

echo "Copying files..."
# Copy binary
chmod +x lite-xl
mkdir -p $HOME/.local/bin
mv -f lite-xl $HOME/.local/bin/
xdg-desktop-menu forceupdate

# Copy core and addons
rm -rf $HOME/.local/share/lite-xl
mkdir -p $HOME/.local/share/lite-xl
mv -f data/* $HOME/.local/share/lite-xl/

echo "Installing LSP..."
mkdir -p $HOME/.config/lite-xl/
cd $HOME/.config/lite-xl/
git clone https://github.com/lite-xl/lite-xl-lsp plugins/lsp
git clone https://github.com/lite-xl/lite-xl-widgets libraries/widget
git clone https://github.com/liquidev/lintplus plugins/lintplus
wget https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/snippets.lua -O plugins/snippets.lua
wget https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/lsp_snippets.lua -O plugins/lsp_snippets.lua

python -m pip install --break-system-packages python-lsp-server
npm install -g bash-language-server
npm install -g dockerfile-language-server-nodejs

echo "Cleaning up..."
rm -rf $TMPDIR

