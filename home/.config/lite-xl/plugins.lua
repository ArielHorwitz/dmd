local config = require "core.config"

config.plugins.autosave.enabled = false
config.plugins.autocomplete.max_height = 15
config.plugins.autocomplete.min_len = 1
config.plugins.autoreload.always_show_nagview = true
config.plugins.bracketmatch.line_size = 4
config.plugins.drawwhitespace = { enabled = true, show_leading = false, show_middle_min = 2 }
config.plugins.lineguide.width = 3
config.plugins.lineguide.enabled = true
config.plugins.lineguide.rulers = { [1] = 80, [2] = 100, [3] = 120 }
config.plugins.linewrapping.enable_by_default = false
config.plugins.linewrapping.mode = "word"
config.plugins.lsp.mouse_hover_delay = 750
config.plugins.lsp.more_yielding = true
config.plugins.lsp.symbolstree_visibility = "hide"
