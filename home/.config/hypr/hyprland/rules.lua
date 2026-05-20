hl.window_rule({
    name = "tiling-by-default",
    match = { class = ".*" },
    tile = true,
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-file-upload",
    match = { initial_class = "firefox", initial_title = "(File Upload)" },
    float = true,
})

hl.window_rule({
    name = "explicit-floating",
    match = { class = ".*_make_window_float_.*" },
    float = true,
})

hl.workspace_rule({ workspace = "s[true]", gaps_in = 10, gaps_out = 50 })

hl.window_rule({
    name = "fullscreen-maximized",
    match = { fullscreen_state_internal = 1 },
    border_color = { colors = { "rgba(ff6666ee)", "rgba(1155ffee)" }, angle = 30 },
})

hl.window_rule({
    name = "fullscreen-full",
    match = { fullscreen_state_internal = 2 },
    border_color = { colors = { "rgba(ff6666ee)", "rgba(1155ffee)" }, angle = 30 },
})

hl.window_rule({
    name = "ignore-maximize-requests",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- ~>>>
-- ~>>> home
hl.workspace_rule({ workspace = "n[e:0]", layout_opts = { direction = "left" } })
-- ~<<<
