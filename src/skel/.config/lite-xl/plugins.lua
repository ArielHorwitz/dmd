------------------------------- Plugins ---------------------------------------

local config = require "core.config"


-- Builtin plugins
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
config.plugins.treeview.visible = false

