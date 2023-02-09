#!/bin/bash

BASE=$1
BASENAME=$( basename "$BASE" )
CRITIC="$HOME/Mozda/Jwebmsounds/dlanor_critic.mkv"
DIMENSIONS=$( ffprobe -i "$CRITIC" 2>&1 | grep -o "[0-9]\+x[0-9]\+" )

convert "$BASE" -resize "$DIMENSIONS"\! "/tmp/resized_$BASENAME"
ffmpeg -i "/tmp/resized_$BASENAME" -i "$CRITIC" -filter_complex '[1:v]colorkey=0x00fe00:0.3:0.2[ckout];[0:v][ckout]overlay[out]' -map '[out]' -map 1:a -c:a copy "$HOME/Desktop/critic.mp4"

rm -f "/tmp/resized_$BASENAME"