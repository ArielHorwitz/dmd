------------------------------- General ---------------------------------------

local config = require "core.config"


config.indent_size = 4
config.mouse_wheel_scroll = 270
config.scroll_past_end = true
config.file_size_limit = 5

-- Animations
-- config.transitions = false
config.animation_rate = 0.5

-- Miscallaneous
config.fps = 30
config.borderless = false
config.always_show_tabs = true
config.tab_close_button = false

config.ignore_files = {
  -- folders
  "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
  "^node_modules/", "^%.cache/", "^__pycache__/", "^venv/", "^target/",
  -- files
  "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
  "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
  "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
  "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
}


----------------------------- Load Config -------------------------------------

require "keybinds"
require "style"
require "plugins"
require "lsp"


-------------------------------- Notes ----------------------------------------

-- DATADIR - installed Lite XL Lua code, default color schemes and fonts.
-- USERDIR - configuration directory.

