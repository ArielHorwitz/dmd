local config = require "core.config"

-- Editor
config.indent_size = 4
config.mouse_wheel_scroll = 270
config.scroll_past_end = true
config.file_size_limit = 5

-- Animations
config.transitions = true
config.animation_rate = 0.5

-- Miscallaneous
config.fps = 30
config.borderless = false
config.always_show_tabs = true
config.tab_close_button = false

config.ignore_files = {
  -- FOLDERS
  "^%..-cache.-/", "^__pycache__/",
  "^venv/", "^.venv/", "^target/",
  "^%.svn/", "^%.git/", "^%.hg/", "^CVS/",
  "^node_modules/",
  -- FILES
  "%.pyc$", "%.pyo$",
  "%.o$", "%.a$", "%.so$", "%.obj$", "%.lib$", "%.dylib$",
  "%.exe$", "%.dll$", "^%.DS_Store$",
}

require "keybinds"
require "style"
require "plugins"
require "lsp"
require "snippets"
