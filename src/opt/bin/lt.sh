#!/bin/bash

tree_args="-aC"
tree_ignore="-I .git/ -I venv/"
less_args="--quit-if-one-screen --shift .2 --use-color -R"

tree $@ $tree_args $tree_ignore | less $less_args
