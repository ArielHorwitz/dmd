------------------------------- Keybinds --------------------------------------

local keymap = require "core.keymap"
local add = keymap.add


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


-------------------------------- Notes ----------------------------------------

-- Default keybindings:
-- https://lite-xl.com/en/documentation/keymap


-- COMMANDS LIST
--
-- command:complete
-- command:escape
-- command:select-next
-- command:select-previous
-- command:submit
-- core:add-directory
-- core:change-project-folder
-- core:find-command
-- core:find-file
-- core:force-quit
-- core:new-doc
-- core:new-named-doc
-- core:open-file
-- core:open-log
-- core:open-project-folder
-- core:open-project-module
-- core:open-user-module
-- core:quit
-- core:reload-module
-- core:remove-directory
-- core:restart
-- core:toggle-fullscreen
-- dialog:next-entry
-- dialog:previous-entry
-- dialog:select
-- dialog:select-no
-- dialog:select-yes
-- doc:backspace
-- doc:copy
-- doc:create-cursor-next-line
-- doc:create-cursor-previous-line
-- doc:cut
-- doc:delete
-- doc:delete-lines
-- doc:delete-to-{name}
-- doc:duplicate-lines
-- doc:go-to-line
-- doc:indent
-- doc:join-lines
-- doc:lower-case
-- doc:move-lines-down
-- doc:move-lines-up
-- doc:move-to-{name}
-- doc:move-to-next-char
-- doc:move-to-previous-char
-- doc:newline
-- doc:newline-above
-- doc:newline-below
-- doc:paste
-- doc:redo
-- doc:reload
-- doc:save
-- doc:save-as
-- doc:select-all
-- doc:select-lines
-- doc:select-none
-- doc:select-to-cursor
-- doc:select-to-{name}
-- doc:select-word
-- doc:set-cursor
-- doc:set-cursor-line
-- doc:set-cursor-word
-- doc:split-cursor
-- doc:toggle-block-comments
-- doc:toggle-line-comments
-- doc:toggle-line-ending
-- doc:undo
-- doc:unindent
-- doc:upper-case
-- emptyview:new-doc
-- end-of-doc
-- end-of-line
-- end-of-word
-- file:delete
-- file:rename
-- files:create-directory
-- find-replace:find
-- find-replace:previous-find
-- find-replace:repeat-find
-- find-replace:replace
-- find-replace:replace-in-selection
-- find-replace:replace-symbol
-- find-replace:select-add-all
-- find-replace:select-add-next
-- find-replace:select-next
-- find-replace:select-previous
-- find-replace:toggle-regex
-- find-replace:toggle-sensitivity
-- log:copy-to-clipboard
-- log:open-as-doc
-- next-block-end
-- next-char
-- next-line
-- next-page
-- next-word-end
-- previous-block-start
-- previous-char
-- previous-line
-- previous-page
-- previous-word-start
-- root:close
-- root:close-all
-- root:close-all-others
-- root:close-or-quit
-- root:grow
-- root:horizontal-scroll
-- root:move-tab-left
-- root:move-tab-right
-- root:scroll
-- root:scroll-hovered-tabs-backward
-- root:scroll-hovered-tabs-forward
-- root:scroll-tabs-backward
-- root:scroll-tabs-forward
-- root:shrink
-- root:split-{dir}
-- root:switch-to-{dir}
-- root:switch-to-hovered-next-tab
-- root:switch-to-hovered-previous-tab
-- root:switch-to-next-tab
-- root:switch-to-previous-tab
-- root:switch-to-tab-{i}
-- start-of-doc
-- start-of-indentation
-- start-of-line
-- start-of-word
-- status-bar:disable-messages
-- status-bar:enable-messages
-- status-bar:hide
-- status-bar:hide-item
-- status-bar:reset-items
-- status-bar:show
-- status-bar:show-item
-- status-bar:toggle
-- tabbar:new-doc

