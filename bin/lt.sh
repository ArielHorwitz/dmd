#!/bin/bash

tree_args="-aC"
tree_ignore="-I .git/ -I venv/ -I __pycache__/ -I *.egg-info/ -I target/"

tree $@ $tree_args $tree_ignore | bat
