-------------------------------- Style ----------------------------------------

local core = require "core"
local style = require "core.style"


-------------------------------- Theme ----------------------------------------

core.reload_module("colors.synthwave")


-------------------------------- Fonts ----------------------------------------

style.code_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/firacode/FiraCodeNerdFont-Regular.ttf",
  8 * SCALE
)
style.font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  8 * SCALE
)
style.big_font = renderer.font.load(
  "/home/wiw/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf",
  14 * SCALE
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

