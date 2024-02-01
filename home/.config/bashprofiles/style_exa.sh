#! /usr/bin/bash

# File classes
#     fi Normal file
#     di Directory
#     ex Executable file
#     pi Named pipe
#     so Socket
#     bd Block device
#     cd Character device
#     ln Symlink
#     or Broken symlink

# Permissions
#     ur User +r bit
#     uw User +w bit
#     ux User +x bit (files)
#     ue User +x bit (file types)
#     gr Group +r bit
#     gw Group +w bit
#     gx Group +x bit
#     tr Others +r bit
#     tw Others +w bit
#     tx Others +x bit
#     su Higher bits (files)
#     sf Higher bits (other types)
#     xa Extended attribute marker

# File sizes
#     sn Size numbers
#     sb Size unit
#     df Major device ID
#     ds Minor device ID

# Owners and Groups
#     uu A user that’s you
#     un A user that’s not
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
#     da Timestamp
#     in File inode
#     bl Number of blocks
#     hd Table header row
#     lp Symlink path
#     cc Control character

# Overlays
#     bO Broken link path

C+="fi=38;5;15" # normal file
C+=":sn=38;5;166" # size number
C+=":sb=38;5;8" # size unit
C+=":da=38;5;8" # timestamp

export EXA_COLORS=$C

