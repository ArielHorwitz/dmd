#! /bin/bash

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_STATE_HOME=$HOME/.local/state
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_DOWNLOAD_DIR=$HOME/temp
export XDG_DOCUMENTS_DIR=$HOME/temp
export XDG_DESKTOP_DIR=$HOME/temp
export XDG_MUSIC_DIR=$HOME/media/music
export XDG_PICTURES_DIR=$HOME/media/pics
export XDG_VIDEOS_DIR=$HOME/media/video

export PAGER=bat
export VISUAL=lite-xl
export EDITOR=lite-xl
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000
~>>>
~>>> zen
export QT_SCALE_FACTOR=2.0
~<<<

extra_paths_prepend=(
    "$HOME/.local/bin/testing"
    "$HOME/.cargo/bin"
)

extra_paths_append=(
    "$HOME/.local/bin"
)

export PATH=$(withpath ${extra_paths_append[@]})
export PATH=$(withpath -p ${extra_paths_prepend[@]})
