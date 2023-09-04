#| --------------------
AUDIO
-------------------- |#
(deflayer audio
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aimt @volu @aium @sksp XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @prev @vold @next @skhd XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aomt @vol0 @aoum XX    _                        XX           XX    XX    XX    XX
  _     _     _                 @pp               _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    sksp (cmd-button "pa2pci")
    skhd (cmd-button "pa2usb")
    volu (cmd-button "volumeup")
    vold (cmd-button "volumedown")
    vol0 (cmd-button "volumezero")
    aimt (cmd-button "micmute")
    aium (cmd-button "micunmute")
    aomt (cmd-button "mute")
    aoum (cmd-button "unmute")
    prev PreviousSong
    next NextSong
    pp   PlayPause
)

