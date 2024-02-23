local style = require "core.style"
local common = require "core.common"

style.background = { common.color "#1a1b26" }
style.background2 = { common.color "#16161e" }
style.background3 = { common.color "#24283b" }
style.text = { common.color "#a9b1d6" }
style.caret = { common.color "#a9b1d6" }
style.accent = { common.color "#7aa2f7" }
style.dim = { common.color "#565f89" }
style.divider = { common.color "#101014" }
style.selection = { common.color "#282B3C" }
style.line_number = { common.color "#363B54" }
style.line_number2 = { common.color "#737AA2" }
style.line_highlight = { common.color "#1E202E"}
style.scrollbar = { common.color "#24283b" }
style.scrollbar2 = { common.color "#414868" }

style.syntax["normal"] = { common.color "#9abdf5" }
style.syntax["symbol"] = { common.color "#00d2d2" }
style.syntax["comment"] = { common.color "#414868" }
style.syntax["keyword"] = { common.color "#6749ff" }
style.syntax["keyword2"] = { common.color "#51a200" }
style.syntax["number"] = { common.color "#4078f2" }
style.syntax["literal"] = { common.color "#c0caf5" }
style.syntax["string"] = { common.color "#008b2e" }
style.syntax["operator"] = { common.color "#2ac3de"}
style.syntax["function"] = { common.color "#7aa2f7" }

-- PLUGINS
style.lint_warning = { common.color "#e80000" }
style.bracketmatch_color = { common.color "#bb77ff" }
style.guide = { common.color "#1E202E" }
style.guide_highlight = { common.color "#363B54" }
style.guide_width = 1
