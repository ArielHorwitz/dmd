-- Tiling / floating

hl.window_rule({
    name = "tiling-by-default",
    match = { class = ".*" },
    tile = true,
    suppress_event = "maximize",
})

hl.window_rule({
    name = "firefox-float-file-upload",
    match = { initial_class = "firefox", initial_title = "(File Upload)" },
    float = true,
})

hl.window_rule({
    name = "audacity-float-popups",
    match = { class = "Audacity" },
    float = true,
})
hl.window_rule({
    name = "audacity-tile-main",
    match = { class = "Audacity", initial_title = "^Audacity$" },
    tile = true,
})

hl.window_rule({
    name = "explicit-floating",
    match = { class = ".*_make_window_float_.*" },
    float = true,
})


-- Style

hl.workspace_rule({
    workspace = "s[true]",
    gaps_in = 10,
    gaps_out = 50,
})

hl.window_rule({
    name = "fullscreen-maximized-color",
    match = { fullscreen_state_internal = 1 },
    border_color = { colors = { "rgba(ff6666ee)", "rgba(1155ffee)" }, angle = 30 },
})

hl.window_rule({
    name = "fullscreen-full-color",
    match = { fullscreen_state_internal = 2 },
    border_color = { colors = { "rgba(ff6666ee)", "rgba(1155ffee)" }, angle = 30 },
})


-- Behavior

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
