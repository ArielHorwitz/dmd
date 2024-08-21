------------------------------- Keybinds --------------------------------------

local keymap = require "core.keymap"
local add = keymap.add

add({ ["ctrl+shift+r"] = "doc:reload" }, true)
add({ ["ctrl+alt+shift+r"] = "core:restart" }, true)
add({ ["ctrl+shift+e"] = "lsp:restart-servers" }, true)

-- Navigation
add({ ["alt+down"] = "root:switch-to-down" }, true)
add({ ["alt+left"] = "root:switch-to-left" }, true)
add({ ["alt+right"] = "root:switch-to-right" }, true)
add({ ["alt+up"] = "root:switch-to-up" }, true)

add({ ["alt+shift+down"] = "root:split-down" }, true)
add({ ["alt+shift+left"] = "root:split-left" }, true)
add({ ["alt+shift+right"] = "root:split-right" }, true)
add({ ["alt+shift+up"] = "root:split-up" }, true)

add({ ["ctrl+pagedown"] = "root:switch-to-next-tab" }, true)
add({ ["ctrl+pageup"] = "root:switch-to-previous-tab" }, true)

add({ ["ctrl+alt+pagedown"] = "root:move-tab-right" }, true)
add({ ["ctrl+alt+pageup"] = "root:move-tab-left" }, true)

add({ ["ctrl+shift+\\"] = "treeview:toggle-focus" }, true)


-- Editor
add({ ["ctrl+alt+u"] = "doc:upper-case" }, true)
add({ ["ctrl+alt+shift+u"] = "doc:lower-case" }, true)


-- Plugins
add({ ["alt+l"] = "hybrid-line-numbers:toggle" }, true)
add({ ["alt+shift+m"] = "markers:toggle-marker" }, true)
add({ ["alt+m"] = "markers:go-to-next-marker" }, true)
add({ ["alt+b"] = "git blame:toggle" }, true)

-------------------------------- Notes ----------------------------------------

-- Default keybindings:
-- https://lite-xl.com/en/documentation/keymap

