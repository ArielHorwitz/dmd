(deflayer audio
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aimt @volu @aium @sksp XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @prev @vold @next @skhd XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @aomt @vol0 @aoum XX    _                        XX           XX    XX    XX    XX
  _     _     _                 @pp               _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    sksp (cmd-button "iukmessenger --default alsa_output.pci-0000_00_1f.3.analog-stereo")
    skhd (cmd-button "iukmessenger --default alsa_output.pci-0000_00_1f.3.analog-stereo")
    volu (cmd-button "iukmessenger audio --increase 5")
    vold (cmd-button "iukmessenger audio --decrease 5")
    vol0 (cmd-button "iukmessenger audio 0")
    aimt (cmd-button "micmute")
    aium (cmd-button "micunmute")
    aomt (cmd-button "iukmessenger audio --mute")
    aoum (cmd-button "iukmessenger audio --unmute")
    prev PreviousSong
    next NextSong
    pp   PlayPause
)

