#!/bin/bash

[ -d $(pwd)/winners ] || mkdir $(pwd)/winners

feh --info "printf '%S%5s%wx%h'" --zoom max --scale-down -g 1280x720 -B black -d --action1 "gio trash %F" --action2 "mv %F $(pwd)/winners/"  $( ls $(pwd) | grep subgweh | shuf -n 1 | sed -r "s|$|/*|g" ); find $(pwd) -empty -type d -delete