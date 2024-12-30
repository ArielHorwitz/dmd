#! /bin/bash

C=

# File classes
#     fi Normal file
C+="fi=38;5;15"
#     di Directory
C+=":di=38;5;27"
#     ex Executable file
C+=":ex=38;5;40"
#     pi Named pipe
#     so Socket
#     bd Block device
#     cd Character device
#     ln Symlink
C+=":ln=3;38;5;43"
#     or Broken symlink

# Permissions
#     ur User +r bit
C+=":ur=38;5;142;4;1"
#     gr Group +r bit
C+=":gr=38;5;100"
#     tr Others +r bit
C+=":tr=38;5;142;1"
#     uw User +w bit
C+=":uw=38;5;124;4;1"
#     gw Group +w bit
C+=":gw=38;5;88"
#     tw Others +w bit
C+=":tw=38;5;124;1"
#     ux User +x bit (files)
C+=":ux=38;5;34;4;1"
#     ue User +x bit (file types)
C+=":ue=38;5;34;4;1"
#     gx Group +x bit
C+=":gx=38;5;28"
#     tx Others +x bit
C+=":tx=38;5;34;1"
#     su Higher bits (files)
#     sf Higher bits (other types)
#     xa Extended attribute marker

# File sizes
#     sn Size numbers
C+=":sn=38;5;166"
#     sb Size unit
C+=":sb=38;5;8"
#     df Major device ID
#     ds Minor device ID

# Owners and Groups
#     uu A user that’s you
C+=":uu=38;5;142"
#     un A user that’s not
C+=":un=38;5;124"
#     gu A group with you in it
#     gn A group without you

# Hard links
#     lc Number of links
#     lm A multi-link file

# Git
#     ga New
#     gm Modified
#     gd Deleted
#     gv Renamed
#     gt Type change

# Details and metadata
#     xx Punctuation
C+=":xx=38;5;240"
#     da Timestamp
C+=":da=38;5;91"
#     in File inode
#     bl Number of blocks
#     hd Table header row
#     lp Symlink path
C+=":lp=38;5;43"
#     cc Control character

# Overlays
#     bO Broken link path

export EZA_COLORS=$C
