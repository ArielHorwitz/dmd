(deflayer base
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  @sys  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    @wnav @edit XX    @txtm XX    home  up    end   pgup  XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  @text @audi @scrp XX    @mous XX    XX    left  down  right pgdn  XX    _                               XX    XX    XX
  _     @lnch XX    XX    XX    XX    XX    XX    XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    base (around (layer-switch base) (cmd-button "setlayer base"))
    text (around (layer-switch text) (cmd-button "setlayer text"))
    mous (layer-toggle mouse)
    txtm (layer-toggle text_macros)
    sys  (layer-toggle system)
    wnav (layer-toggle window_navigation)
    scrp (layer-toggle scratchpad)
    lnch (layer-toggle launchers)
    edit (layer-toggle editing)
    audi (layer-toggle audio)
)

