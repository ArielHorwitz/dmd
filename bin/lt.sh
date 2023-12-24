#!/bin/bash

ignore="*.git"
exa -laFTR --group-directories-first --git-ignore -I $ignore --color=always $@ | bat

