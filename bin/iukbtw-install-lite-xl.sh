#!/usr/bin/bash
set -e

sudo -v
DATADIR=$PWD/`dirname "$0"`
TMPDIR="/tmp/install-lite-xl/"
CONFIG_DIR="$HOME/.config/lite-xl/"
printcolor -s info "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

# Download latest Lite XL
printcolor -s ok "Downloading latest release..."
asset_pattern="*addons-linux-x86_64-portable.tar.gz"
downloaded_filename="lite-xl.tar.gz"
gh release download --repo 'lite-xl/lite-xl' -p $asset_pattern -O $downloaded_filename

printcolor -s ok "Extracting..."
tar -xzf $downloaded_filename
cd lite-xl

printcolor -s ok "Deleting existing plugins..."
rm -rf $HOME/.local/share/lite-xl

printcolor -s ok "Copying files..."
# Copy binary
mkdir -p $HOME/.local/bin
mv -f lite-xl $HOME/.local/bin/
chmod +x $HOME/.local/bin/lite-xl
# Copy core and addons
mkdir -p $HOME/.local/share/lite-xl
mv -f data/* $HOME/.local/share/lite-xl/

# XDG menus
printcolor -s ok "Populating XDG application..."
DESKTOP_APPS="$HOME/.local/share/applications/"
mkdir -p $DESKTOP_APPS
echo '[Desktop Entry]
Type=Application
Name=Lite XL
Comment=A lightweight text editor written in Lua
Exec=lite-xl %F
# Icon=lite-xl
Terminal=false
StartupWMClass=lite-xl
Categories=Development;IDE;
MimeType=text/plain;inode/directory;' > $DESKTOP_APPS/lite-xl.desktop
# DESKTOP_ICONS="$HOME/.local/share/icons/hicolor/48x48/apps/"
# cp lite-xl.png
xdg-desktop-menu forceupdate

printcolor -s ok "Installing 'lpm' plugin manager..."
URL="https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux"
curl -sSL $URL -o $HOME/.local/bin/lpm
chmod +x $HOME/.local/bin/lpm

printcolor -s ok "Installing plugins..."
lpm install --quiet --assume-yes autoinsert bracketmatch wordcount

printcolor -s ok "Installing LSP..."
mkdir -p $CONFIG_DIR
sparse_clone() {
    set -e
    local repo_url=https://github.com/$1
    local target_dir=$CONFIG_DIR/$2
    rm -rf $target_dir
    git clone -q $repo_url $target_dir
}
download_repo_file() {
    set -e
    local file_url=https://raw.githubusercontent.com/$1
    local target_file=$CONFIG_DIR/$2
    mkdir -p $(dirname $target_file)
    curl -sSL $file_url -o $target_file
}
sparse_clone 'lite-xl/lite-xl-lsp' 'plugins/lsp'
sparse_clone 'lite-xl/lite-xl-widgets' 'libraries/widget'
sparse_clone 'liquidev/lintplus' 'plugins/lintplus'
download_repo_file 'vqns/lite-xl-snippets/main/snippets.lua' 'plugins/snippets.lua'
download_repo_file  'vqns/lite-xl-snippets/main/lsp_snippets.lua' 'plugins/lsp_snippets.lua'
printcolor -s ok "Installing Python LSP..."
python -m pip install -q --break-system-packages python-lsp-server
printcolor -s ok "Installing Rust LSP..."
[[ $(command -v rust-analyzer) ]] || rustup component add rust-analyzer
printcolor -s ok "Installing Lua LSP..."
sudo pacman -Sq --needed --noconfirm lua-language-server
printcolor -s ok "Installing Bash LSP..."
sudo npm install --silent --no-progress --global bash-language-server
printcolor -s ok "Installing Dockerfile LSP..."
sudo npm install --silent --no-progress --global dockerfile-language-server-nodejs

printcolor -s ok "Cleaning up temporary working directory $TMPDIR"
rm -rf $TMPDIR
