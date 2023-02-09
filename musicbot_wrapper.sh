#!/bin/bash

if [ $# -eq 0 ]; then
    echo "You need to provide a music directory as the first argument"
    exit 1
fi

[[ -z "$(pactl list short modules | grep "DiscordSink")" ]] && /bin/bash $HOME/stuf/scripts/minivac.sh -l
firstfile=$(find "$(realpath "$1")" -type f -iregex ".*\.\(mp3\|flac\|m4a\|ogg\)$" | sort | head -n 1)

if [ -z "$firstfile" ]; then
    echo "Could not find any music files in given directory"
    exit 1
fi

pgrep -f "MPV Local Music Bot" >/dev/null 2>&1 && pkill -f "MPV Local Music Bot"
nohup /usr/bin/mpv --title="MPV Local Music Bot" --force-window=yes --geometry=750x750+710+290 --volume=80 --loop-file=inf --af="loudnorm=I=-25:TP=-1.5:LRA=1" "$firstfile" >/dev/null 2>&1 &
while [[ $window == "" || $window == *$'\n'* ]]; do window=$(xdotool search --name "MPV Local Music Bot"); done
sleep 0.5 && xdotool key --window "$window" Control_L+o

#MPV WINDOW / SOME OTHER OUTPUT
sinkinput=$(pactl list sink-inputs | grep -E "^\s*Sink\ Input\ \#|^\s*media\.name\ \=\ " | tac | grep -A 1 -E "^\s*media\.name\ \=\ .*MPV\ Local\ Music\ Bot.*" | grep -oP "Sink\ Input\ \#\K[0-9]+")

#SINK
#sink=$(pacmd list-sinks | grep -E "^\s*name:|^\s*module:" | grep -A 1 -E "^\s*name: <CombinedDiscordSink>" | grep -oP "module: \K[0-9]+")
#IS HOW IT WAS SUPPOSED TO BE, BUT
sink="CombinedDiscordSink"
#IS ENOUGH
#SET THE SINK TO alsa_output.pci-0000_03_04.0.analog-stereo TO PUT IT BACK

pactl move-sink-input "$sinkinput" "$sink"

#--af-add='dynaudnorm=g=5:f=250:r=0.9:p=0.5'