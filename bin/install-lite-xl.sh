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
    -f "app;Clear and install lite-xl"
    -f "lpm;Install lpm"
    -f "plugins;Install plugins"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


clear_installed() {
    set -e
    rm -f $BIN_DIR/lite-xl
    rm -f $BIN_DIR/lpm
    rm -rf $DATA_DIR
    rm -rf $CONFIG_DIR
}

install_lite_xl() {
    set -e
    cd $TMPDIR

    printcolor -s ok "Downloading latest release [$(gh-latest lite-xl)]..."
    download_url=$(gh-latest -A lite-xl | rg 'addons-linux-x86_64-portable.tar.gz')
    downloaded_filename='lite-xl.tar.gz'
    curl -sSL $download_url -o $downloaded_filename

    printcolor -s ok "Extracting..."
    tar -xzf $downloaded_filename
    cd lite-xl

    printcolor -s ok "Installing binary and plugins..."
    install -Dt $BIN_DIR lite-xl

    printcolor -s ok "Replacing existing plugins..."
    rm -rf $DATA_DIR
    mkdir -p $DATA_DIR
    mv -f data/* $DATA_DIR
}

update_xdg_menus() {
    set -e
    cd $TMPDIR

    printcolor -s ok "Downloading icon..."
    DESKTOP_ICONS="$HOME/.local/share/icons/hicolor/48x48/apps/"
    mkdir -p $DESKTOP_ICONS
    ICON_URL="https://raw.githubusercontent.com/lite-xl/lite-xl/master/resources/icons/lite-xl.svg"
    curl -sSL $ICON_URL -o $DESKTOP_ICONS/lite-xl.svg

    printcolor -s ok "Populating XDG application..."
    DESKTOP_APPS="$HOME/.local/share/applications/"
    mkdir -p $DESKTOP_APPS
    echo '[Desktop Entry]
    Type=Application
    Name=Lite XL
    Comment=A lightweight text editor written in Lua
    Exec=lite-xl %F
    Icon=lite-xl
    Terminal=false
    StartupWMClass=lite-xl
    Categories=Development;IDE;
    MimeType=text/plain;inode/directory;' > $DESKTOP_APPS/lite-xl.desktop

    xdg-desktop-menu forceupdate
}

install_lpm() {
    set -e
    cd $TMPDIR

    printcolor -s ok "Installing 'lpm' plugin manager..."
    URL="https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/latest/lpm.x86_64-linux"
    curl -sSL $URL -o lpm
    install -Dt $BIN_DIR lpm
}

install_plugins() {
    set -e
    printcolor -s ok "Installing plugins..."
    lpm repo add https://github.com/ArielHorwitz/lite-xl-plugins:dev
    lpm install --assume-yes $(< $args_plugins_file)
}

printcolor -s info "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR

if [[ $args_clear ]]; then
    clear_installed
fi

if [[ $args_full || $args_app ]]; then
    clear_installed
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
