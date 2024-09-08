#! /bin/bash

tail -n 500 -F $@ | bat -n --paging=never -l log

