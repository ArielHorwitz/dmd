#| ---------------------------------------------------------------------------------------------------------------------------
BASE
--------------------------------------------------------------------------------------------------------------------------- |#
(deflayer base
  _     _     _     _     _     _     _     _     _     _     _     _     _            @test XX    @kill
  @i3wm XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    @wnav @edit XX    @txtm XX    home  up    end   pgup  XX    XX    XX     @rkrl XX    XX     XX    XX    XX    XX
  @text @audi @scrp XX    @mous XX    XX    left  down  right pgdn  XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    test (cmd-button "$HOME/.test")
    base (around (layer-switch base) (cmd-button "sudo /opt/iukbtw/bin/setlayer base"))
    text (around (layer-switch text) (cmd-button "sudo /opt/iukbtw/bin/setlayer text"))
    mous (layer-toggle mouse)
    txtm (layer-toggle text_macros)
    i3wm (layer-toggle i3wm)
    wnav (layer-toggle window_navigation)
    scrp (layer-toggle scratchpad)
    edit (layer-toggle editing)
    audi (layer-toggle audio)
    rkrl (cmd-button "mpv ~/media/rr.mkv --fullscreen --no-input-default-bindings")
    kill (cmd-button "sleep 0.1 ; pkill -x kmonad")
)

#| --------------------
i3 MANAGEMENT
-------------------- |#
(deflayer i3wm
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    @brtd @brtu @tgwt  XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    @wmrb XX    XX    XX    @i3re @wmlo @wmpo XX    XX    @tgbr  XX    XX    XX     XX    XX    XX    XX
  _     XX    @wmss @wmds XX    XX    XX    XX    @kmdr @wmlk XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    kmdr (cmd-button "pkill -x kmonad ; sleep 0.1 ; kmdrun")
    i3re (cmd-button "i3-msg restart")
    wmlk (cmd-button "loginctl lock-session")
    wmds (cmd-button "displaygeometry --file .iukdisplays")
    wmlo (cmd-button "i3-msg exit")
    wmss (cmd-button "loginctl lock-session && systemctl suspend")
    wmhb (cmd-button "systemctl hibernate")
    wmpo (cmd-button "systemctl poweroff")
    wmrb (cmd-button "systemctl reboot")
    brtu (cmd-button "sudo setmonbrightness --increase")
    brtd (cmd-button "sudo setmonbrightness --decrease")
    tgwt (cmd-button "i3-msg border toggle")
    tgbr (cmd-button "i3-msg bar mode toggle, bar hidden_state hide")
)

#| --------------------
MOUSE
-------------------- |#
(deflayer mouse
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  @mou0 XX    XX    XX    XX    XX    XX    @msb1 @msu1 @msb3 @msb4 XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     @mou4 @mou3 @mou2 XX    XX    XX    @msl1 @msd1 @msr1 @msb5 XX    @mstg                           XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @msps @mscn @msrs XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    mstg (cmd-button "touchpadtoggle")
    mou0 (layer-toggle mouse0)
    mou1 (layer-toggle mouse1)
    mou2 (layer-toggle mouse2)
    mou3 (layer-toggle mouse3)
    mou4 (layer-toggle mouse4)
    mscn (cmd-button "mousecenter")
    msps (cmd-button "xdotool mousedown 1")
    msrs (cmd-button "xdotool mouseup 1")

    msb1 (cmd-button "xdotool click 1")
    msb3 (cmd-button "xdotool click 3")
    msb4 (cmd-button "xdotool click 4")
    msb5 (cmd-button "xdotool click 5")

    msu0 (cmd-button "xdotool mousemove_relative 0 -1")
    msd0 (cmd-button "xdotool mousemove_relative 0 1")
    msl0 (cmd-button "xdotool mousemove_relative -- -1 0")
    msr0 (cmd-button "xdotool mousemove_relative 1 0")

    msu1 (cmd-button "xdotool mousemove_relative 0 -10")
    msd1 (cmd-button "xdotool mousemove_relative 0 10")
    msl1 (cmd-button "xdotool mousemove_relative -- -10 0")
    msr1 (cmd-button "xdotool mousemove_relative 10 0")

    msu2 (cmd-button "xdotool mousemove_relative 0 -30")
    msd2 (cmd-button "xdotool mousemove_relative 0 30")
    msl2 (cmd-button "xdotool mousemove_relative -- -30 0")
    msr2 (cmd-button "xdotool mousemove_relative 30 0")

    msu3 (cmd-button "xdotool mousemove_relative 0 -90")
    msd3 (cmd-button "xdotool mousemove_relative 0 90")
    msl3 (cmd-button "xdotool mousemove_relative -- -90 0")
    msr3 (cmd-button "xdotool mousemove_relative 90 0")

    msu4 (cmd-button "xdotool mousemove_relative 0 -270")
    msd4 (cmd-button "xdotool mousemove_relative 0 270")
    msl4 (cmd-button "xdotool mousemove_relative -- -270 0")
    msr4 (cmd-button "xdotool mousemove_relative 270 0")
)

(deflayer mouse0
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @msu0 _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     @msl0 @msd0 @msr0 _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer mouse1
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @msu1 _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     @msl1 @msd1 @msr1 _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer mouse2
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @msu2 _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     @msl2 @msd2 @msr2 _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer mouse3
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @msu3 _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     @msl3 @msd3 @msr3 _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer mouse4
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     @msu4 _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     @msl4 @msd4 @msr4 _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)

#| --------------------
EDITING
-------------------- |#
(deflayer editing
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @undo XX    @redo XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     @sela @save XX    XX    XX    XX    bspc  XX    del   XX    XX    XX    _                               XX    XX
  _     XX    XX    XX    XX    XX    XX    @copy @cut  @past XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    copy C-c
    past C-v
    cut  C-x
    undo C-z
    redo C-r
    save C-s
    sela C-a
)

#| --------------------
WINDOW NAVIGATION
-------------------- |#
(deflayer window_navigation
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     @klps XX    @kltb XX    @wtgt XX    @wprv @fup  @wnxt @wmfp XX    XX    @wrnm  XX    XX    XX     XX    XX    XX    XX
  _     XX    @scrw @scrd @fuls @wtgs XX    @flft @fdwn @frgt @wmfc XX    @wtrm                           XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     @wman             @wrof             _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    wman (layer-toggle window_manipulation)
    klps (cmd-button "i3-msg kill")
    kltb C-w
    wrnm (cmd-button "settitle")
    scrw (cmd-button "screenshot")
    scrd (cmd-button "screenshotdesktop")
    wtrm (cmd-button "alacritty")
    wrof (cmd-button "rofi -show drun")
    wtgt (cmd-button "i3-msg layout toggle tabbed split && mousewarp")
    wtgs (cmd-button "i3-msg layout toggle split && mousewarp")
    fuls (cmd-button "i3-msg fullscreen toggle && mousewarp")
    wnxt (cmd-button "i3-msg workspace next && mousewarp")
    wprv (cmd-button "i3-msg workspace prev && mousewarp")
    frgt (cmd-button "i3-msg focus right && mousewarp")
    flft (cmd-button "i3-msg focus left && mousewarp")
    fup  (cmd-button "i3-msg focus up && mousewarp")
    fdwn (cmd-button "i3-msg focus down && mousewarp")
    wmfp (cmd-button "i3-msg focus parent")
    wmfc (cmd-button "i3-msg focus child")
)


#| --------------------
WINDOW MANIPULATION
-------------------- |#
(deflayer window_manipulation
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    @wsrn XX    XX    @wszl @wmvu @wszr @wszu XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    @wtmd XX    XX    @wmvl @wmvd @wmvr @wszd XX    @wmmw                           XX    XX    XX
  _     XX    XX    XX    XX    XX    @wsn  @wsml @wmvc @wsmr XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    wtmd (cmd-button "i3-msg focus mode_toggle && mousewarp")
    wsn  (cmd-button "userprompt -p 'Workspace name: ' -e 'i3-msg workspace {{}}'")
    wsml (cmd-button "i3-msg move workspace to output left && mousewarp")
    wsmr (cmd-button "i3-msg move workspace to output right && mousewarp")
    wmvl (cmd-button "i3-msg move left 50 px or 5 ppt && mousewarp")
    wmvr (cmd-button "i3-msg move right 50 px or 5 ppt && mousewarp")
    wmvu (cmd-button "i3-msg move up 25 px or 5 ppt && mousewarp")
    wmvd (cmd-button "i3-msg move down 25 px or 5 ppt && mousewarp")
    wmvc (cmd-button "windowcenter && mousewarp")
    wmmw (cmd-button "userprompt -p 'Move window to workspace: ' -e 'i3-msg move to workspace {{}}' && mousewarp")
    wsrn (cmd-button "userprompt -p 'Rename workspace: ' -e 'i3-msg rename workspace to {{}}' && mousewarp")
    wszr (cmd-button "i3-msg resize grow width 50 px or 5 ppt && mousewarp")
    wszl (cmd-button "i3-msg resize shrink width 50 px or 5 ppt && mousewarp")
    wszu (cmd-button "i3-msg resize grow height 25 px or 5 ppt && mousewarp")
    wszd (cmd-button "i3-msg resize shrink height 25 px or 5 ppt && mousewarp")
)

#| --------------------
SCRATCHPAD
-------------------- |#
(deflayer scratchpad
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps7 @sps8 @sps9 XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps4 @sps5 @sps6 XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @sps1 @sps2 @sps3 XX    _                        XX           XX    XX    XX    XX
  _     _     @scpa             @sps0             _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    scpa (layer-toggle scratchpad_alt)
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
)


#| --------------------
SCRATCHPAD MANIPULATION
-------------------- |#
(deflayer scratchpad_alt
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm7 @spm8 @spm9 XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm4 @spm5 @spm6 XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @spm1 @spm2 @spm3 XX    _                        XX           XX    XX    XX    XX
  _     _     _                 @tgfl             _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    tgfl (cmd-button "i3-msg floating toggle && mousewarp")
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


#| --------------------
AUDIO
-------------------- |#
(deflayer audio
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
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

#| --------------------
TEXT MACROS
-------------------- |#
(deflayer text_macros
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    @webs XX    XX    XX    XX    XX    XX    XX    @lorm XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    @lmgt XX    XX    XX    @lnkd XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    @name @mail XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    name #(A r i e l spc H o r w i t z)
    mail #(a r i e l . h o r w i t z @ g m a i l . c o m)
    webs #(h t t p s : / / a r i e l . n i n j a)
    lorm #(L o r e m spc i p s u m spc d o l o r spc s i t spc a m e t , spc c o n s e c t e t u r spc a d i p i s c i n g spc e l i t . spc U t spc s o d a l e s spc r i s u s spc m a t t i s , spc m a t t i s spc l e c t u s spc a , spc m o l l i s spc e n i m . spc P e l l e n t e s q u e spc t e m p o r spc b l a n d i t spc n e q u e spc e u spc f r i n g i l l a . spc P r o i n spc v e n e n a t i s spc p o r t a spc o r n a r e . spc M a e c e n a s spc t e m p o r spc l e c t u s .)
    lnkd #(h t t p s : / / w w w . l i n k e d i n . c o m / i n / a r i e l - h o r w i t z /)
    lmgt #(h t t p s : / / l m g t f y . a p p / ? q =)
)

#| ---------------------------------------------------------------------------------------------------------------------------
TEXT
--------------------------------------------------------------------------------------------------------------------------- |#
(deflayer text
  _     _     _     _     _     _     _     _     _     _     _     _     _            _     _     @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  @base _     _     _     _     _     _     _     _     _     _     _     _                               _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _                        _            _     _     _     _
  _     @txt2 _                 _                 _     _     _     _                  _     _     _      _     _
)
(defalias
    txt2 (layer-toggle text_alt)
)

#| --------------------
ALT TEXT
-------------------- |#
(deflayer text_alt
  _     _     _     _     _     _     _     _     _     _     _     _     _            _     _     _
  _     @engl @hebr _     _     _     _     _     _     \(    \)    _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     /     7     8     9     -     _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     *     4     5     6     +     _     _                               _     _     _
  caps  _     _     _     _     _     0     1     2     3     .     _                        _            _     _     _     _
  _     _     _                 0                 _     _     _     _                  _     _     _      _     _
)
(defalias
    engl (cmd-button "setxkbmap us")
    hebr (cmd-button "setxkbmap il")
)


#| ---------------------------------------------------------------------------------------------------------------------------
CONFIG AND SOURCE
--------------------------------------------------------------------------------------------------------------------------- |#
(defcfg
    input  (device-file "DEVICE_FILE_PATH")
    output (uinput-sink "iukbtw" "sleep 0.1")
    fallthrough true
    allow-cmd true
)
(defsrc
  esc   f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12          ssrq  slck  pause
  grv   1     2     3     4     5     6     7     8     9     0     -     =     bspc   ins   home  pgup   nlck  kp/   kp*   kp-
  tab   q     w     e     r     t     y     u     i     o     p     [     ]     \      del   end   pgdn   kp7   kp8   kp9   kp+
  caps  a     s     d     f     g     h     j     k     l     ;     '     ret                             kp4   kp5   kp6
  lsft  z     x     c     v     b     n     m     ,     .     /     rsft                     up           kp1   kp2   kp3   kprt
  lctl  lmet  lalt              spc               ralt  rmet  cmp   rctl               left  down  rght   kp0   kp.
)
(deflayer normal_keyboard
  esc   f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12          ssrq  slck  pause
  grv   1     2     3     4     5     6     7     8     9     0     -     =     bspc   ins   home  pgup   nlck  kp/   kp*   kp-
  tab   q     w     e     r     t     y     u     i     o     p     [     ]     \      del   end   pgdn   kp7   kp8   kp9   kp+
  caps  a     s     d     f     g     h     j     k     l     ;     '     ret                             kp4   kp5   kp6
  lsft  z     x     c     v     b     n     m     ,     .     /     rsft                     up           kp1   kp2   kp3   kprt
  lctl  lmet  lalt              spc               ralt  rmet  cmp   rctl               left  down  rght   kp0   kp.
)
(deflayer blocked_all_but_modifiers
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer transparent
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    @kill
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      XX    XX    XX     XX    XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _     _                               XX    XX    XX
  _     _     _     _     _     _     _     _     _     _     _     _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    nrml (layer-toggle normal_keyboard)
)
