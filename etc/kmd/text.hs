(deflayer editing
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    XX    XX    @undo XX    @redo XX    XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     @sela @save XX    XX    XX    XX    bspc  XX    del   XX    XX    XX    _                               XX    XX
  _     XX    XX    XX    XX    XX    XX    @copy @cut  @past XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(deflayer text
  _     _     _     _     _     _     _     _     _     _     _     _     _            _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  @base _     _     _     _     _     _     _     _     _     _     _     _                               _     _     _
  @txt2 _     _     _     _     _     _     _     _     _     _     _                        _            _     _     _     _
  _     @txt1 _                 _                 _     _     _     _                  _     _     _      _     _
)
(deflayer text_alt
  _     _     _     _     _     _     _     _     _     _     _     _     _            _     _     _
  _     @engl @hebr _     _     _     _     _     _     \(    \)    _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     /     7     8     9     -     _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     *     4     5     6     +     _     _                               _     _     _
  caps  _     _     _     _     _     0     1     2     3     .     _                        _            _     _     _     _
  _     _     _                 0                 _     _     _     _                  _     _     _      _     _
)
(deflayer text_alt2
  _     _     _     _     _     _     _     _     _     _     _     _     _            _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  _     _     _     _     _     _     _     _     _     _     _     _     _     _      _     _     _      _     _     _     _
  caps  _     _     _     _     _     _     _     _     _     _     _     _                               _     _     _
  XX    _     _     _     _     _     _     _     _     _     _     _                        _            _     _     _     _
  _     _     _                 _                 _     _     _     _                  _     _     _      _     _
)
(deflayer text_macros
  _     _     _     _     _     _     _     _     _     _     _     _     _            XX    XX    XX
  XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    XX    _      XX    XX    XX     XX    XX    XX    XX
  _     XX    @webs XX    XX    XX    XX    XX    XX    XX    @lorm XX    XX    XX     XX    XX    XX     XX    XX    XX    XX
  _     XX    XX    XX    XX    @lmgt XX    XX    XX    @lnkd XX    XX    _                               XX    XX    XX
  _     XX    XX    XX    XX    XX    @name @mail XX    XX    XX    _                        XX           XX    XX    XX    XX
  _     _     _                 _                 _     _     _     _                  XX    XX    XX     XX    XX
)
(defalias
    txt1 (layer-toggle text_alt)
    txt2 (around lsft (layer-toggle text_alt2))
    engl (cmd-button "setxkbmap us")
    hebr (cmd-button "setxkbmap il")
    copy C-c
    past C-v
    cut  C-x
    undo C-z
    redo C-y
    save C-s
    sela C-a

    name #(A r i e l spc H o r w i t z)
    mail #(a r i e l . h o r w i t z @ g m a i l . c o m)
    webs #(h t t p s : / / a r i e l . n i n j a)
    lorm #(L o r e m spc i p s u m spc d o l o r spc s i t spc a m e t , spc c o n s e c t e t u r spc a d i p i s c i n g spc e l i t . spc U t spc s o d a l e s spc r i s u s spc m a t t i s , spc m a t t i s spc l e c t u s spc a , spc m o l l i s spc e n i m . spc P e l l e n t e s q u e spc t e m p o r spc b l a n d i t spc n e q u e spc e u spc f r i n g i l l a . spc P r o i n spc v e n e n a t i s spc p o r t a spc o r n a r e . spc M a e c e n a s spc t e m p o r spc l e c t u s .)
    lnkd #(h t t p s : / / w w w . l i n k e d i n . c o m / i n / a r i e l - h o r w i t z /)
    lmgt #(h t t p s : / / l m g t f y . a p p / ? q =)
)

