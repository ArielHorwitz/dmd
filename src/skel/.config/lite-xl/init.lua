local core = require "core"
local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"


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

-- key binding:
-- keymap.add { ["ctrl+escape"] = "core:quit" }

-- pass 'true' for second parameter to overwrite an existing binding
-- keymap.add({ ["ctrl+pageup"] = "root:switch-to-previous-tab" }, true)
-- keymap.add({ ["ctrl+pagedown"] = "root:switch-to-next-tab" }, true)

 keymap.add({ ["alt+down"] = "root:switch-to-down" }, true)
 keymap.add({ ["alt+left"] = "root:switch-to-left" }, true)
 keymap.add({ ["alt+right"] = "root:switch-to-right" }, true)
 keymap.add({ ["alt+up"] = "root:switch-to-up" }, true)


------------------------------- Fonts ----------------------------------------

-- customize fonts:
style.code_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/firacode/FiraCodeNerdFont-Regular.ttf",
  12 * SCALE
)
style.font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  10 * SCALE
)
style.big_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  14 * SCALE
)


-- DATADIR is the location of the installed Lite XL Lua code, default color
-- schemes and fonts.
-- USERDIR is the location of the Lite XL configuration directory.
--
-- font names used by lite:
-- style.font          : user interface
-- style.big_font      : big text in welcome screen
-- style.icon_font     : icons
-- style.icon_big_font : toolbar icons
-- style.code_font     : code
--
-- the function to load the font accept a 3rd optional argument like:
--
-- {antialiasing="grayscale", hinting="full", bold=true, italic=true, underline=true, smoothing=true, strikethrough=true}
--
-- possible values are:
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


--------------------------------- LSP -----------------------------------------
local lspconfig = require "plugins.lsp.config"

lspconfig.pylsp.setup()
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

