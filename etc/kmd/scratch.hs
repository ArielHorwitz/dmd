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
    tgfl (cmd-button "i3-msg floating toggle && mousewarp")
    sps0 (cmd-button "i3-msg scratchpad show")
    sps1 (cmd-button "scratchpad -s 1 && mousewarp")
    sps2 (cmd-button "scratchpad -s 2 && mousewarp")
    sps3 (cmd-button "scratchpad -s 3 && mousewarp")
    sps4 (cmd-button "scratchpad -s 4 && mousewarp")
    sps5 (cmd-button "scratchpad -s 5 && mousewarp")
    sps6 (cmd-button "scratchpad -s 6 && mousewarp")
    sps7 (cmd-button "scratchpad -s 7 && mousewarp")
    sps8 (cmd-button "scratchpad -s 8 && mousewarp")
    sps9 (cmd-button "scratchpad -s 9 && mousewarp")
    spm1 (cmd-button "scratchpad -m 1 && mousewarp")
    spm2 (cmd-button "scratchpad -m 2 && mousewarp")
    spm3 (cmd-button "scratchpad -m 3 && mousewarp")
    spm4 (cmd-button "scratchpad -m 4 && mousewarp")
    spm5 (cmd-button "scratchpad -m 5 && mousewarp")
    spm6 (cmd-button "scratchpad -m 6 && mousewarp")
    spm7 (cmd-button "scratchpad -m 7 && mousewarp")
    spm8 (cmd-button "scratchpad -m 8 && mousewarp")
    spm9 (cmd-button "scratchpad -m 9 && mousewarp")
)

