#! /bin/bash
set -e

USER_ENV=~/.local/share/pyv
USER_VENV=~/.local/share/pyv/base_venv
CURRENT_DIR_NAME=$(basename $(pwd))

APP_NAME=$(basename "$0")
ABOUT="Create virtual environments for Python using virtualenv."
CLI=(
    --prefix "args_"
    -o "name;Name for new virtual environment;$CURRENT_DIR_NAME"
    -O "dir;Directory name for new virtual environment;venv;d"
    -O "python_version;Python version to use;;p"
    -f "print;Print the virtual environment used by $APP_NAME and exit;;P"
    -f "manage;Manage the virtual environment used by $APP_NAME and exit;;M"
    -f "noconfirm;Do not ask for confirmation;;Y"
    -f "uninstall;Remove the default environment used for pyv;;U"
    -e "virtualenv_args;Arguments for virtualenv"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# Shortcut operations
if [[ -n $args_uninstall ]]; then
    [[ -n $args_noconfirm ]] || promptconfirm -d "Uninstall?"
    printcolor -s ok "Uninstalling pyv from: $USER_ENV"
    rm -rf $USER_ENV
    exit 0
fi

# Install
if [[ ! -d $USER_VENV ]]; then
    printcolor -s ok "Installing pyv at: $USER_ENV"
    mkdir --parent $USER_ENV
    python -m venv $USER_VENV
    source $USER_VENV/bin/activate
    pip install --upgrade pip virtualenv >/dev/null
    printcolor -s ok "Installed pyv at: $USER_ENV"
fi

source $USER_VENV/bin/activate || exit_error "Failed to activate pyv. Try (--install)"

if [[ -n $args_print ]]; then
    echo $VIRTUAL_ENV
elif [[ -n $args_manage ]]; then
    printcolor -s notice "$APP_NAME venv: $VIRTUAL_ENV"
    virtualenv $args_virtualenv_args
else
    # Create new
    [[ ! -d $args_dir ]] || exit_error "Directory already exists"
    # Select python version
    if [[ -n $args_python_version ]]; then
        args_virtualenv_args+=("--python python${args_python_version}")
    fi
    # Create venv
    [[ -n $args_noconfirm ]] || promptconfirm -d "Create new venv \"$args_name\" in directory \"$args_dir\"?"
    virtualenv $args_virtualenv_args --prompt $args_name $args_dir
    # Activate
    source $args_dir/bin/activate
    # Update pip
    pip install --upgrade pip
    # Print environment path
    printcolor -s notice "New venv: $VIRTUAL_ENV"
fi
