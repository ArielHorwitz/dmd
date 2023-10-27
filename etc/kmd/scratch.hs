(deflayer scratchpad
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps7 @sps8 @sps9 XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps4 @sps5 @sps6 XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps1 @sps2 @sps3 XX    _                        XX           XX    XX    XX    XX
  _     _     @scpa             @sps0             _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer scratchpad_alt
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm7 @spm8 @spm9 XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm4 @spm5 @spm6 XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm1 @spm2 @spm3 XX    _                        XX           XX    XX    XX    XX
  _     _     _                 @tgfl             _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    scpa (layer-toggle scratchpad_alt)
    tgfl (cmd-button "i3-msg floating toggle && iukmessenger mouse --window")
    sps0 (cmd-button "i3-msg scratchpad show")
    sps1 (cmd-button "iukmessenger scratch -s 1")
    sps2 (cmd-button "iukmessenger scratch -s 2")
    sps3 (cmd-button "iukmessenger scratch -s 3")
    sps4 (cmd-button "iukmessenger scratch -s 4")
    sps5 (cmd-button "iukmessenger scratch -s 5")
    sps6 (cmd-button "iukmessenger scratch -s 6")
    sps7 (cmd-button "iukmessenger scratch -s 7")
    sps8 (cmd-button "iukmessenger scratch -s 8")
    sps9 (cmd-button "iukmessenger scratch -s 9")
    spm1 (cmd-button "iukmessenger scratch -m 1")
    spm2 (cmd-button "iukmessenger scratch -m 2")
    spm3 (cmd-button "iukmessenger scratch -m 3")
    spm4 (cmd-button "iukmessenger scratch -m 4")
    spm5 (cmd-button "iukmessenger scratch -m 5")
    spm6 (cmd-button "iukmessenger scratch -m 6")
    spm7 (cmd-button "iukmessenger scratch -m 7")
    spm8 (cmd-button "iukmessenger scratch -m 8")
    spm9 (cmd-button "iukmessenger scratch -m 9")
)

