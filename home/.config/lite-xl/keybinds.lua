-- Default keybindings: https://lite-xl.com/en/documentation/keymap

local keymap = require "core.keymap"

keymap.add(
  {
    -- Basic
    ["ctrl+shift+r"] = "doc:reload",
    ["ctrl+shift+l"] = "core:open-log",
    ["ctrl+alt+shift+r"] = "core:restart",
    ["ctrl+shift+e"] = "lsp:restart-servers",
    -- Navigation
    ["alt+down"] = "root:switch-to-down",
    ["alt+left"] = "root:switch-to-left",
    ["alt+right"] = "root:switch-to-right",
    ["alt+up"] = "root:switch-to-up",
    ["alt+shift+down"] = "root:split-down",
    ["alt+shift+left"] = "root:split-left",
    ["alt+shift+right"] = "root:split-right",
    ["alt+shift+up"] = "root:split-up",
    ["ctrl+pagedown"] = "root:switch-to-next-tab",
    ["ctrl+pageup"] = "root:switch-to-previous-tab",
    ["ctrl+alt+pagedown"] = "root:move-tab-right",
    ["ctrl+alt+pageup"] = "root:move-tab-left",
    ["ctrl+shift+\\"] = "treeview:toggle-focus",
    -- Editor
    ["ctrl+alt+u"] = "doc:upper-case",
    ["ctrl+alt+shift+u"] = "doc:lower-case",
    -- Macros
    ["f12"] = "macro:toggle-record",
    ["shift+f12"] = "macro:play",
    -- Plugins
    ["alt+l"] = "hybrid-line-numbers:toggle",
    ["alt+shift+m"] = "markers:toggle-marker",
    ["alt+m"] = "markers:go-to-next-marker",
    ["alt+b"] = "git blame:toggle",
    ["ctrl+f1"] = "bookmarks:open-bookmark",
    ["ctrl+f2"] = "bookmarks:add-bookmark",
    ["ctrl+shift+["] = "exfold:fold",
    ["ctrl+shift+]"] = "exfold:expand",
  },
  true
)
