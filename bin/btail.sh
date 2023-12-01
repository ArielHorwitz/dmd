#! /usr/bin/bash

tail -n 500 -f $1 | bat --paging=never -l log

