hl.monitor({
    output = "desc:HOMUX_VARIABLE_MONITOR_HOME_LEFT",
    mode = "preferred",
    scale = 1.0,
    position = "0x0",
})
hl.monitor({
    output = "desc:HOMUX_VARIABLE_MONITOR_HOME_RIGHT",
    mode = "preferred",
    scale = 1.0,
    position = "2560x0",
})
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    ~>>>
    scale = 1.0,
    ~>>> desk
    scale = "auto",
    mirror = "desc:HOMUX_VARIABLE_MONITOR_HOME_LEFT",
    ~<<<
})
hl.monitor({
    output = "",
    position = "auto",
    mode = "preferred",
    scale = "auto",
})
