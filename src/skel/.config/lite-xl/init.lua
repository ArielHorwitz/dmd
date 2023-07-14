local core = require "core"
local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"

-- DATADIR - installed Lite XL Lua code, default color schemes and fonts.
-- USERDIR - configuration directory.


----------------------------- General ----------------------------------------

config.indent_size = 4
config.mouse_wheel_scroll = 270
config.scroll_past_end = true
config.file_size_limit = 5

-- Animations
config.transitions = false
config.animation_rate = 0.5
config.disabled_transitions.scroll = true

-- Miscallaneous
config.fps = 30
config.borderless = false
config.always_show_tabs = true
config.tab_close_button = false

-- config.ignore_files = {
--   -- folders
--   "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
--   "^node_modules/", "^%.cache/", "^__pycache__/", "%.egg-info/",
--   -- files
--   "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
--   "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
--   "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
--   "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
-- }


------------------------------ Themes ----------------------------------------

core.reload_module("colors.synthwave")

--------------------------- Key bindings -------------------------------------

keymap.add({ ["alt+down"] = "root:switch-to-down" }, true)
keymap.add({ ["alt+left"] = "root:switch-to-left" }, true)
keymap.add({ ["alt+right"] = "root:switch-to-right" }, true)
keymap.add({ ["alt+up"] = "root:switch-to-up" }, true)
keymap.add({ ["alt+shift+down"] = "root:split-down" }, true)
keymap.add({ ["alt+shift+left"] = "root:split-left" }, true)
keymap.add({ ["alt+shift+right"] = "root:split-right" }, true)
keymap.add({ ["alt+shift+up"] = "root:split-up" }, true)


------------------------------- Fonts ----------------------------------------

style.code_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/firacode/FiraCodeNerdFont-Regular.ttf",
  12
)
style.font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  10
)
style.big_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  14
)
-- style.icon_font
-- style.icon_big_font

-- Third argument options:
-- antialiasing: grayscale, subpixel
-- hinting: none, slight, full
-- bold: true, false
-- italic: true, false
-- underline: true, false
-- smoothing: true, false
-- strikethrough: true, false


------------------------------ Plugins ----------------------------------------

config.plugins.autocomplete.desc_font_size = 6
config.plugins.autocomplete.max_height = 10
config.plugins.autocomplete.min_len = 1
config.plugins.autoreload.always_show_nagview = true
config.plugins.lineguide.enabled = true
config.plugins.lineguide.rulers = { [1] = 80, [2] = 90 }
config.plugins.linenumbers.relative = true
config.plugins.linewrapping.mode = "word"
config.plugins.lsp.more_yielding = true
config.plugins.nerdicons.draw_tab_icons = true
config.plugins.nerdicons.draw_treeview_icons = true
config.plugins.spellcheck = "/home/wiw/.local/share/dict/words"
config.plugins.treeview.size = 420
config.plugins.treeview.hide_on_startup = true


--------------------------------- LSP -----------------------------------------
local lspconfig = require "plugins.lsp.config"

lspconfig.pylsp.setup {
  settings = {
    pylsp = {
      plugins = {
        flake8 = {
          maxLineLength = 88,
          enabled = true,
        },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        pycodestyle = { enabled = false },
        pydocstyle = { enabled = false },
        pyflakes = { enabled = false },
        pylint = { enabled = false },
      }
    }
  }
}
lspconfig.rls.setup()
lspconfig.dockerls.setup()
lspconfig.bashls.setup()
lspconfig.yamlls.setup()
lspconfig.sumneko_lua.setup {
  command = {
    "/home/wiw/temp/lua-language-server/lua-language-server",
    "-E",
    "/home/wiw/temp/lua-language-server/main.lua",
  },
  settings = {
    Lua = {
      diagnostics = {
        enable = false
      }
    }
  }
}

