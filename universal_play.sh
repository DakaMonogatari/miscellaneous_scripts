#!/bin/bash


# THE FINAL SOLUTION
# DEPENDENCIES: sox, cmus
# ANOTHER OPTION WOULD BE TO DMENU ALL THE OPTIONS, SO IT CAN BE RUN WITH ONLY ONE KEYBOARD SHORTCUT
# AND I CAN'T HELP BUT THINK THAT THERE'S SOME WAY TO UNIFY THE PLAYLIST TYPES AND THE SINGLE-SONG BRANCH AND USE ONLY FLAGS INSTEAD OF IF
# ALSO IT WOULD PROBABLY RUN FASTER IF I REPLACED EVERY FIND WITH LOCATE
# OH WELL

# look into types of parentheses, $(( )) is math for example
# shuf is a thing
# also xargs -r is a thing

# [ "$(printf "Yes\\nNo" | dmenu -l 2 -i -p "Send $file to the trash?")" = "Yes" ]


[[ ! $(pgrep -x cmus) ]] && xfce4-terminal -e cmus && exit


SHORTCUTS=(
    'FUNCTION              |     TERMINAL EQUIVALENT                  |     RECOMMENDED KEYBIND'
    '------------------------------------------------------------------------------------------'
    'Play Song             |     play.sh                              |     F8'
    'Queue Song            |     play.sh -q                           |     F9'
    'Notify-send Queue     |     play.sh -n                           |     F10'
    'Play/Pause Song       |     cmus-remote -u                       |     Shift+F8'
    'Skip to Next Song     |     cmus-remote --next                   |     Shift+F9'
    'Toggle Autoplay       |     cmus-remote -C "toggle continue"     |     Ctrl+F9'
    'Play Playlist         |     play.sh -l                           |     Ctrl+Shift+F8'
    'Queue Playlist        |     play.sh -lq                          |     Ctrl+Shift+F9'
    'Clear Playlist        |     play.sh -c                           |     Ctrl+Shift+F10'
    'Increase Volume       |     cmus-remote -v +5%                   |     Shift+Upper side mouse button'
    'Decrease Volume       |     cmus-remote -v -5%                   |     Shift+Lower side mouse button'
)

playlist_flag=false
queue_flag=false
clear_flag=false
current_song=$(cmus-remote -Q | grep file | sed "s|file ||g")

MUSIC="$HOME/music"
SONG=""
SED_STRING="s|^|player-play |"
ROFI_THEME="BernBlue"

#E0E04B
#AAAA00

while getopts "hnlqc" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-n notify-send queue] [-l list] [-q queue] [-c clear]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;            # PRINT HELP IN TERMINAL
#   n) notify-send -u low -t 15000 -i $HOME/stuf/rikanom.png "Songs currently in queue:" "$(cmus-remote -C 'save -q -' | sed -r 's|^\/([^\/]+\/)+||g' )"; exit ;;                    # NOTIFY-SEND QUEUE 
    n) $HOME/stuf/scripts/notification_wrapper.sh "\n> $( echo $current_song | sed -r 's|^\/([^\/]+\/)+||g' ) \n$( cmus-remote -C 'save -q -' | sed -r 's|^\/([^\/]+\/)+||g' | head -n 50 )" "UNIVPLAY" ; exit ;; # NOTIFY-SEND QUEUE VIA OWN WRAPPER
    l) playlist_flag=true; ROFI_THEME="BernViolet" ;;                                                                   # SET PLAYLIST FLAG, CHANGE DMENU COLOR
    q) queue_flag=true; SED_STRING="s|^|add -q |"; ROFI_THEME="${ROFI_THEME}Queue" ;;                                                 # SET QUEUE FLAG, CHANGE DMENU TEXT
    c) clear_flag=true; ROFI_THEME="BernRed" ;;                                                                 # SET CLEAR FLAG, CHANGE DMENU COLOR/TEXT
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done

if $clear_flag ; then
    
    CHOICE=$(echo -e "1. Keep only the currently playing song\n2. Clear everything\n3. Abort" \
    | rofi -dmenu -i -no-custom -p "" -theme "$ROFI_THEME" -async-pre-read 3 -no-click-to-exit )
    echo "$CHOICE" | grep "1" &> /dev/null && cmus-remote -q -c
    # fuck you cmus
    echo "$CHOICE" | grep "2" &> /dev/null && cmus-remote -q -c && sox -n -r 44100 -c 2 /tmp/silence.wav trim 0.0 0.5 && cmus-remote -C "player-play /tmp/silence.wav" && rm /tmp/silence.wav && cmus-remote -C "set continue=false"
    exit
fi




if $playlist_flag ; then

    # FIND EVERY DIRECTORY WITH AN AUDIO FILE IN IT AND PIPE IT INTO DMENU
    PL_DIR=$(find $MUSIC -type f -iregex ".*\.\(mp3\|flac\|m4a\|ogg\)$" -printf '%h/\n' | uniq \
    | rofi -dmenu -i -no-custom -p "" -theme "$ROFI_THEME" -async-pre-read 15 -no-click-to-exit )   

    if [[ -n $PL_DIR ]]; then
	
        $queue_flag || cmus-remote -q -c                                                                                          # || OPERATOR; IF QUEUE FLAG IS FALSE, THEN CLEAR THE QUEUE
        find "$PL_DIR" -maxdepth 1 -type f | sort | sed "s|^|add -q |" | sed -r "s|'|\\\'|g" | xargs -I{} cmus-remote -C "{}"     # FIND EVERY SONG IN THE DIRECTORY (IGNORING ANY NESTED DIRECTORIES) AND PIPE THEM INTO CMUS-REMOTE
        $queue_flag || cmus-remote -q --next                                                                                      # || OPERATOR; IF QUEUE FLAG IS FALSE, PUSH THE FIRST-QUEUED SONG
	$queue_flag || cmus-remote -p                                                                                             # || OPERATOR; IF QUEUE FLAG IS FALSE, PLAY THE PUSHED SONG
        cmus-remote -C "set continue=true"                                                                                        # ENABLE AUTOPLAY
	cmus-remote -C "set play_library=false"                                                                                   # DISABLE ORDINARY PLAYLIST PLAYBACK JUST IN CASE
    fi

else
    
    # FIND EVERY AUDIO FILE AND PIPE IT INTO ROFI, IN TWO LINES
    SONG=$( find $MUSIC -type f -iregex ".*\.\(mp3\|flac\|m4a\|ogg\)$" -printf '/%P\n' | sort --version-sort | sed -r "s|(^\/([^\/]+\/)+)(([^\/])+$)|\1\n\3\x0f|g; $ s|.{1}$||" | paste -sd '\n\0' \
    | rofi -dmenu -sep '\x0f' -eh 2 -i -no-custom -p "" -theme "$ROFI_THEME" -async-pre-read 15 -no-click-to-exit | paste -sd '' )

    [[ -n $SONG ]] && [[ -n "$current_song" ]] && ! $queue_flag && cmus-remote -C "add -Q $current_song"                                              # IF QUEUE FLAG IS FALSE, PLACE CURRENTLY PLAYING SONG AT THE END OF THE QUEUE
    [[ -n $SONG ]] && echo "${MUSIC}${SONG}" | sed "$SED_STRING" | cmus-remote                                                                                    # MUCH CLEANER THAN DMENU
    [[ -n $SONG ]] && cmus-remote -C "set continue=$queue_flag"                                                                                       # TOGGLE AUTOPLAY BASED ON CIRCUMSTANCES

fi