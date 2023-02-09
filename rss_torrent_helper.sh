#!/bin/bash

# this helper script is a monument to my personal failings
# a better man would've just modified the parsing in the original script to allow for per-feed downloaders
# but alas


CONFIG_DIR="$HOME/.config/shell-rss-torrent"

for file in $CONFIG_DIR/*.xml; do
    $HOME/stuf/scripts/shell-rss-torrent "$file"
done