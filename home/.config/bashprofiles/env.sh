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
export EDITOR=rnano
export BROWSER=firefox
export HISTSIZE=10000
export HISTFILESIZE=100000
# ~>>>
# ~>>> zen
export QT_SCALE_FACTOR=2.0
# ~<<<


export CASEBOOK_LOG_LEVEL=DEBUG


# Claude
# https://code.claude.com/docs/en/env-vars
# https://code.claude.com/docs/en/data-usage
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
export DISABLE_ERROR_REPORTING=1
export DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1
export DISABLE_AUTO_COMPACT=1
export DISABLE_FEEDBACK_COMMAND=1
export DISABLE_DOCTOR_COMMAND=1
export DISABLE_INSTALL_GITHUB_APP_COMMAND=1
export DISABLE_LOGIN_COMMAND=1
export DISABLE_LOGOUT_COMMAND=1


extra_paths_prepend=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin/testing"
)

extra_paths_append=(
    "$HOME/.local/bin"
)

append_path "${extra_paths_append[@]}"
prepend_path "${extra_paths_prepend[@]}"
