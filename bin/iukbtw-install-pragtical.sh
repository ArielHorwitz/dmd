#!/usr/bin/bash
set -e

CACHE_DIR="/tmp/install-pragtical/"
USER_DIR="$HOME/.config/pragtical/"
DATA_DIR="$HOME/.local/share/pragtical/"
BINARY_PATH="$HOME/.local/bin/pragtical"
DESKTOP_ICONS="$HOME/.local/share/icons/hicolor/48x48/apps/"
DESKTOP_APPS="$HOME/.local/share/applications/"
LOGO_URL='https://pragtical.dev/img/logo.svg'
PLUGINS=(
    snippets
    lsp
    lintplus
    linenumbers
    autoinsert
    bracketmatch
    gitblame
    gitdiff_highlight
    indentguide
    markers
    rainbowparen
    sticky_scroll
    wordcount
)

APP_NAME=$(basename "$0")
ABOUT="Install the Pragttical editor."
CLI=(
    --prefix "args_"
    -f "force-download;Force downloading without using the cached download;;f"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

sudo -v

printcolor -s info "Cache directory: $CACHE_DIR"
[[ -z $args_force_download ]] || rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR
cd $CACHE_DIR

# Download latest portable Pragtical
printcolor -s ok "Downloading latest release..."
asset_pattern="*linux-x86_64-portable.tar.gz"
downloaded_filename="pragtical.tgz"
# asset_pattern="*.AppImage"
# downloaded_filename="pragtical.AppImage"
[[ -f $downloaded_filename ]] || gh release download --repo 'pragtical/pragtical' -p $asset_pattern -O $downloaded_filename

printcolor -s ok "Extracting..."
tar -xzf $downloaded_filename
cd pragtical

printcolor -s ok "Copying files..."
# Copy binary
printcolor -ns info "Binary: "; echo $BINARY_PATH
mkdir -p $HOME/.local/bin
cp -f pragtical $BINARY_PATH
chmod +x $BINARY_PATH
# Copy data
printcolor -ns info "DATA_DIR: "; echo $DATA_DIR
rm -rf $DATA_DIR
cp -r data $DATA_DIR

# XDG menus
printcolor -s ok "Populating XDG application..."
mkdir -p $DESKTOP_APPS
echo '[Desktop Entry]
Type=Application
Name=Pragtical
Comment=The practical and pragmatic code editor
Exec=pragtical %F
Icon=pragtical
Terminal=false
Categories=Development;IDE;
MimeType=text/plain;inode/directory;' > $DESKTOP_APPS/pragtical.desktop
mkdir -p $DESKTOP_ICONS
[[ -f logo.svg ]] || curl -sSL $LOGO_URL -o logo.svg
cp logo.svg $DESKTOP_ICONS/pragtical.svg

xdg-desktop-menu forceupdate


printcolor -s ok "Installing user config..."
printcolor -ns info "USER_DIR: "; echo $USER_DIR
rm -rf $USER_DIR
mkdir -p $USER_DIR


printcolor -s ok "Installing plugins..."
pragtical pm purge
pragtical pm install ${PLUGINS[@]}

printcolor -s ok "Installing Python LSP..."
python -m pip install -q --break-system-packages python-lsp-server
printcolor -s ok "Installing Rust LSP..."
[[ $(command -v rust-analyzer) ]] || rustup component add rust-analyzer
printcolor -s ok "Installing Lua LSP..."
sudo pacman -Sq --needed --noconfirm lua-language-server
printcolor -s ok "Installing Bash LSP..."
sudo npm install --silent --no-progress --global bash-language-server


printcolor -ns info "Installed Pragtical version: "; pragtical --version
