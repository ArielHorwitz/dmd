#! /bin/bash
set -e

CONFIG_DIR="$HOME/.config/lite-xl/"
DATA_DIR="$HOME/.local/share/lite-xl/"
BIN_DIR="$HOME/.local/bin/"
TMPDIR="/tmp/install-lite-xl/"

PLUGINS_FILE="$HOME/.config/litexl-installer-plugins.txt"


APP_NAME=$(basename "$0")
ABOUT="Install lite-xl and lpm."
CLI=(
    --prefix "args_"
    -O "plugins-file;File specifying which plugins to install using lpm;$PLUGINS_FILE"
    -f "clear;Clear existing installation"
    -f "full;Clear and install everything"
    -f "app;Install/update lite-xl"
    -f "lpm;Install lpm"
    -f "plugins;Install plugins"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


install_lite_xl() {
    sudo -v
    cd $TMPDIR

    printcolor -s ok "Downloading latest release..."
    asset_pattern="*addons-linux-x86_64-portable.tar.gz"
    downloaded_filename="lite-xl.tar.gz"
    gh release download --repo 'lite-xl/lite-xl' -p $asset_pattern -O $downloaded_filename

    printcolor -s ok "Extracting..."
    tar -xzf $downloaded_filename
    cd lite-xl

    printcolor -s ok "Installing binary..."
    install -Dt $BIN_DIR lite-xl

    printcolor -s ok "Replacing existing plugins..."
    rm -rf $DATA_DIR
    mkdir -p $DATA_DIR
    mv -f data/* $DATA_DIR
}

update_xdg_menus() {
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
}

install_lpm() {
    cd $TMPDIR

    printcolor -s ok "Installing 'lpm' plugin manager..."
    URL="https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux"
    curl -sSL $URL -o lpm
    install -Dt $BIN_DIR lpm
}

install_plugins() {
    printcolor -s ok "Installing plugins..."
    lpm install --assume-yes $(< $args_plugins_file)
}

printcolor -s info "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR

if [[ $args_full || $args_clear ]]; then
    rm $BIN_DIR/lite-xl
    rm -rf $DATA_DIR
    rm -rf $CONFIG_DIR
fi
if [[ $args_full || $args_app ]]; then
    install_lite_xl
    update_xdg_menus
fi
if [[ $args_full || $args_lpm ]]; then
    install_lpm
fi
if [[ $args_full || $args_plugins ]]; then
    install_plugins
fi

printcolor -s ok "Cleaning up temporary working directory $TMPDIR"
rm -rf $TMPDIR
