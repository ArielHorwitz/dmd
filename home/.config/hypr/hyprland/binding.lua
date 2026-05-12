hl.bind("SUPER + return", hl.dsp.exec_cmd("alacritty"))
hl.bind("SUPER + ALT + return", hl.dsp.exec_cmd("kmdrun"))
hl.bind("SUPER + ALT + space", hl.dsp.exec_cmd("crowfish"))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
