#! /usr/bin/bash

tail -n 500 -F $@ | bat --paging=never -l log

