local core = require "core"
local style = require "core.style"

core.reload_module("colors.ninja")

local fira_font = "/usr/share/fonts/FiraCode/FiraCodeNerdFont-Regular.ttf"
local mononoki_font = "/usr/share/fonts/Mononoki/mononoki-Regular.ttf"

style.code_font = renderer.font.load(
  fira_font,
-- ~>>>
  14
-- ~>>> lemnos
  15
-- ~>>> zen
  24
-- ~<<<
)
style.font = renderer.font.load(
  mononoki_font,
-- ~>>>
  12
-- ~>>> zen
  24
-- ~<<<
)
style.big_font = renderer.font.load(
  mononoki_font,
-- ~>>>
  12
-- ~>>> zen
  42
-- ~<<<
)
-- style.icon_font
-- style.icon_big_font


-------------------------------- Notes ----------------------------------------

-- Third argument options:
--
-- antialiasing: grayscale, subpixel
-- hinting: none, slight, full
-- bold: true, false
-- italic: true, false
-- underline: true, false
-- smoothing: true, false
-- strikethrough: true, false

