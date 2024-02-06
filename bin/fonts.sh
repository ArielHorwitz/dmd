#! /bin/bash

fc-list | sed 's,:.*,,' | sort -u
