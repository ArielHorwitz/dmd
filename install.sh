#! /bin/bash
set -e

INVOKED_COMMAND="$0 $@"
LOGFILE=/tmp/dmd-install.log
USAGE_HELP="\e[3;32mInstall dmd.\e[0m

\e[1;4mUSAGE:\e[0m $(basename $0) [OPTIONS] [COMPONENTS]

\e[1;4mCOMPONENTS\e[0m
  a | all           All components
  p | packages      Sync system packages
  c | crates        Cargo crate installations
  s | scripts       Bin scripts
  g | config        System configurations
  i | icons         Icons
  f | fonts         Fonts
  h | home          Apply home data using homux

\e[1;4mOPTIONS\e[0m
  -s, --select      Homux selections
  --no-hostname     Do not implicitly add hostname to homux selections
  -r, --reload      Reload home config
  -f, --force       Do not stop on warnings
  -u, --user-mode   Install without root access (local user installation)
  -h, --help        Show this help and exit
"


exec 3>&1 1>/dev/null
printhelp() { printf "$USAGE_HELP" | tee /dev/fd/3 ; }
progress () { printf "\e[32m$1\e[0m\n" | tee /dev/fd/3 ; }
subprogress () { printf "\e[36m$1\e[0m\n" | tee /dev/fd/3 ; }
debug () { printf "\e[36m$1\e[0m\n" ; }
notice () { printf "\e[35m$1\e[0m\n" | tee /dev/fd/3 ; }
warn () { printf "\e[1;38;2;255;96;0m$1\e[0m\n" | tee /dev/fd/3 ; }
error () { printf "\e[31m$1\e[0m\n" | tee /dev/fd/3 ; }
exit_error() { error "$1"; exit 1; }

HOMUX_HOSTNAME=1
HOMUX_SELECTIONS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        a | all)             INSTALL_ALL=1; shift ;;
        p | packages)        INSTALL_PACKAGES=1; shift ;;
        c | crates)          INSTALL_CRATES=1; shift ;;
        s | scripts)         INSTALL_SCRIPTS=1; shift ;;
        g | config)          INSTALL_CONFIG=1; shift ;;
        i | icons)           INSTALL_ICONS=1; shift ;;
        f | fonts)           INSTALL_FONTS=1; shift ;;
        h | home)            INSTALL_HOME=1; shift ;;
        -s | --select )      shift; HOMUX_SELECTIONS+=("$1"); shift ;;
        --no-hostname )      HOMUX_HOSTNAME= ; shift ;;
        -r | --reload)       POST_INSTALL_RELOAD=1; shift ;;
        -f | --force)        INSTALL_FORCE=1; shift ;;
        -u | --user-mode)    USER_MODE=1; shift ;;
        -h | --help)         printhelp; exit 0 ;;
        *)                   exit_error "Unknown option: $1" ;;
    esac
done

INSTALLATION_OPERATION=
INSTALLATION_COMPONENTS=(packages crates scripts config icons fonts home)
for component_name in ${INSTALLATION_COMPONENTS[@]}; do
    installation_component_name="INSTALL_${component_name^^}"
    [[ -z $INSTALL_ALL ]] || declare "${installation_component_name}=1"
    if [[ ${!installation_component_name} ]]; then
        INSTALLATION_OPERATION=1
    fi
done
[[ $INSTALLATION_OPERATION ]] || exit_error "Nothing to do (try --help)"


printf '' > $LOGFILE
exec 1>>$LOGFILE 2>&1
notice "Logging to: $LOGFILE"
echo "Invoked command with arguments: $INVOKED_COMMAND"
echo "Current working directory: $(pwd)"
echo "Started at: $(date)"

SOURCE_DIR=$(realpath $(dirname $0))
SETUP_DIR=$SOURCE_DIR/setup
DMD_DATA_DIR=/var/opt/dmd

if [[ $USER_MODE ]]; then
    CRATES_TARGET=$HOME/.local/bin/dmd_cargo_crates
    BIN_TARGET=$HOME/.local/bin/dmd
    ICONS_TAGRET=$HOME/.local/share/icons/dmd
    FONTS_TARGET_DIR=$HOME/.local/share/fonts
else
    CRATES_TARGET=/bin/dmd_cargo_crates
    BIN_TARGET=/bin/dmd
    ICONS_TAGRET=/usr/share/icons/dmd
    FONTS_TARGET_DIR=/usr/share/fonts
fi


[[ -d $SETUP_DIR ]] || exit_error "Setup directory not found: ${SETUP_DIR}"
[[ $EUID -ne 0 ]] || exit_error "Do not run as root."


decomment() {
    $SOURCE_DIR/bin/decomment.sh "$@"
}


run_with_privilege() {
    if [[ $USER_MODE ]]; then
        "$@"
    else
        sudo "$@"
    fi
}


install_packages() {
    set -e
    if [[ $USER_MODE ]]; then
        warn "Skipping packages installation in user mode (requires root access)"
        warn "Please install these packages manually:"
        warn "$(decomment "$SETUP_DIR/aur.txt" | tr '\n' ' ')"
        return
    fi
    local os_id=$(grep '^ID=' /etc/os-release | awk -F= '{print $2}' | tr -d '"')
    debug "Detected OS: $os_id"
    case $os_id in
        arch   ) install_packages_arch ;;
        *      )
            if [[ $INSTALL_FORCE ]]; then
                warn "Skipping packages installation (OS not supported: $os_id)"
                return
            fi
            exit_error "Cannot install packages (OS not supported: $os_id)"
            ;;
    esac
}

install_packages_arch() {
    set -e
    local aur_helper=paru
    if command -v yay >/dev/null; then
        aur_helper=yay
    elif [[ ! $(command -v paru) ]]; then
        progress "Installing paru..."
        local paru_build_dir=$(mktemp -d)
        sudo pacman -S --needed --noconfirm base-devel git
        git clone --depth 1 --shallow-submodules https://aur.archlinux.org/paru.git $paru_build_dir
        cd $paru_build_dir
        makepkg -si --needed --noconfirm
    fi
    progress "Installing packages..."
    $aur_helper -S --needed --noconfirm $(decomment "$SETUP_DIR/aur.txt")
}

install_crates() {
    set -e
    progress "Installing crates..."
    rustup update
    run_with_privilege mkdir --parents $CRATES_TARGET
    if [[ -z $USER_MODE ]]; then
        sudo chown --recursive $USER $CRATES_TARGET
    fi
    for crate_name in $(decomment "$SETUP_DIR/crates.txt"); do
        subprogress "> $crate_name"
        cargo install --root $CRATES_TARGET $crate_name
    done
    if [[ -z $USER_MODE ]]; then
        sudo chown --recursive 0 $CRATES_TARGET
    fi
}


install_scripts() {
    set -e
    progress "Installing scripts..."
    local staging=$(mktemp -d)
    # stage and remove suffixes
    cp -rt $staging $SOURCE_DIR/bin/*
    find $staging -type f -name "*.*" -execdir bash -c 'mv "$0" "${0%.*}"' {} \;
    # install from staging
    run_with_privilege rm -rf $BIN_TARGET
    if [[ $USER_MODE ]]; then
        mkdir -p $BIN_TARGET
        install -Dt $BIN_TARGET $staging/*
    else
        sudo install --owner root -Dt $BIN_TARGET $staging/*
    fi
    # clean up
    rm -rf $staging
}


install_configs() {
    set -e
    if [[ $USER_MODE ]]; then
        warn "Skipping system configurations in user mode:"
        warn "  - sudoers configuration"
        warn "  - hardware group and udev rules"
        warn "Some scripts or configurations may not work correctly"
        return
    fi

    progress "Configuring profile..."
    cat $SETUP_DIR/profile.dropin \
        | sed "s|<BIN_TARGET>|$BIN_TARGET|g" \
        | sed "s|<CRATES_TARGET>|$CRATES_TARGET/bin|g" \
        | sudo tee /etc/profile.d/dmd.sh

    progress "Configuring sudoers..."
    cat $SETUP_DIR/sudoers.dropin \
        | sed "s|<BIN_TARGET>|$BIN_TARGET|g" \
        | sudo tee /etc/sudoers.d/dmd
    sudo cp $SETUP_DIR/udev.rules /etc/udev/rules.d/80-dmd.rules
    run_with_privilege mkdir -p "$DMD_DATA_DIR"
    sudo chgrp hardware "$DMD_DATA_DIR"
    sudo chmod g+w "$DMD_DATA_DIR"
    sudo groupadd -f hardware
    sudo usermod -aG hardware $USER
}


install_icons() {
    set -e
    progress "Installing icons..."
    run_with_privilege rm -rf $ICONS_TAGRET
    run_with_privilege mkdir -p $ICONS_TAGRET
    run_with_privilege cp -rt $ICONS_TAGRET $SOURCE_DIR/icons/*
}


install_fonts() {
    set -e
    progress "Installing fonts..."
    local font_downloads=(
        FiraCodeNerdFont-"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz"
        MononokiNerdFont-"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Mononoki.tar.xz"
        Ubuntu-"https://assets.ubuntu.com/v1/0cef8205-ubuntu-font-family-0.83.zip"
        Mononoki-"https://github.com/madmalik/mononoki/releases/download/1.6/mononoki.zip"
        NotoColorEmoji-"https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
    )
    local tmpdir=$(mktemp -d)
    fc-cache
    for name_url in ${font_downloads[@]}; do
        local font_name=${name_url%%-*}
        local font_url=${name_url#*-}
        local target_dir=$FONTS_TARGET_DIR/$font_name
        if [[ $(fc-list | grep -i "$target_dir/") ]]; then
            debug "Font '$font_name' already installed at ${target_dir}"
            continue
        fi
        local archive_name=$(basename $font_url)
        local download_file=$tmpdir/$archive_name
        debug "Installing ${font_name}: ${archive_name} at ${target_dir}"
        curl -sSL $font_url -o $download_file
        run_with_privilege rm -rf $target_dir
        run_with_privilege mkdir -p $target_dir
        case $archive_name in
            *.zip       ) run_with_privilege unzip -q $download_file -d $target_dir ;;
            *.tar.*     ) run_with_privilege tar -xf $download_file -C $target_dir ;;
            *.ttf       ) run_with_privilege cp $download_file $target_dir ;;
            *           ) exit_error "Unknown file type for font install: $archive_name" ;;
        esac
        if [[ -z $USER_MODE ]]; then
            sudo chown -R root:root $target_dir
            sudo chmod -R 755 $target_dir
        fi
    done
    rm -r $tmpdir
    fc-cache
}


install_home() {
    set -e
    local selection
    local homux_args=(
        --config-file "$SOURCE_DIR/home/.config/homux/config.toml"
        apply --verbose
    )
    for selection in "${HOMUX_SELECTIONS[@]}"; do
        debug "Adding homux selection: $selection"
        homux_args+=(-s "$selection")
    done
    if [[ "${HOMUX_SELECTIONS[*]}" && $HOMUX_HOSTNAME ]]; then
        local hostname
        hostname=$(hostnamectl hostname)
        debug "Adding hostname as homux selection: $hostname"
        homux_args+=(-s "$hostname")
    fi
    progress "Applying home directory..."
    homux "${homux_args[@]}"
    set_perms
}


set_perms() {
    set -e
    local perm
    local target_path
    local perm_file
    local file_paths
    local old_mode
    local perms_dir="$SOURCE_DIR/setup/perms"
    debug "Setting permissions according to $perms_dir (user: $USER $EUID)"
    for perm_file in "$perms_dir"/*; do
        [[ -f "$perm_file" ]] || continue
        debug "Reading $perm_file"
        perm=$(basename "$perm_file")
        readarray -t file_paths < "$perm_file"
        for path in "${file_paths[@]}"; do
            [[ -n "$path" ]] || continue
            target_path="$HOME/$path"
            if [[ ! -e "$target_path" ]]; then
                warn "Ignoring chmod for non-existent path $target_path"
                continue
            fi
            old_mode=$(stat -c %a "$target_path")
            debug "chmodding $target_path [$old_mode -> $perm]"
            chmod "$perm" "$target_path"
        done
    done
}


post_install_user_config() {
    set -e
    killall -SIGUSR2 waybar || :
    hyprctl dispatch forcerendererreload || :
    killall dunst || :
    kmdrun
}

[[ -z $INSTALL_PACKAGES ]] || install_packages
[[ -z $INSTALL_CRATES ]] || install_crates
[[ -z $INSTALL_SCRIPTS ]] || install_scripts
[[ -z $INSTALL_CONFIG ]] || install_configs
[[ -z $INSTALL_ICONS ]] || install_icons
[[ -z $INSTALL_FONTS ]] || install_fonts
[[ -z $INSTALL_HOME ]] || install_home

if [[ $POST_INSTALL_RELOAD ]]; then
    "$SOURCE_DIR"/bin/reloadhome.sh
fi

progress "Done."
