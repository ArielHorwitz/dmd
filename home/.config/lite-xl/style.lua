-------------------------------- Style ----------------------------------------

local core = require "core"
local style = require "core.style"


-------------------------------- Theme ----------------------------------------

core.reload_module("colors.ninja")


-------------------------------- Fonts ----------------------------------------

local home_dir = os.getenv("HOME")
local fira_font = string.format("%s/.local/share/fonts/firacode/FiraCodeNerdFont-Regular.ttf", home_dir)
local droid_font = string.format("%s/.local/share/fonts/droid/DroidSansMNerdFont-Regular.otf", home_dir)

style.code_font = renderer.font.load(
  fira_font,
-- ~>>>
  14
-- ~>>> lemnos
  15
-- ~>>> zen
  20
-- ~<<<
)
style.font = renderer.font.load(
  droid_font,
-- ~>>>
  12
-- ~>>> zen
  18
-- ~<<<
)
style.big_font = renderer.font.load(
  droid_font,
-- ~>>>
  12
-- ~>>> zen
  18
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

