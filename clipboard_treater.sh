#!/bin/bash

#dependencies: clipnotify

function treater_daemon {
    while clipnotify; do
        CLIP="$(xclip -o -sel clip 2>&1)"
        if ! [[ -f $( echo -n "$CLIP" | head -n 1 ) || -d $( echo -n "$CLIP" | head -n 1 ) || -n $( echo -n "$CLIP" | grep -i "Error: target STRING not available" ) || "$CLIP" -eq "" ]]; then
            echo -n "$CLIP" | sed -r "s|$|\x0f|g" | tr '\n' ' ' |  sed -r "s|-\x0f ||g; s|\x0f||g" | tr -s ' ' | xclip -sel clip
        fi
    done
}

daemon_flag=false;


while getopts "hd" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-d toggle daemon]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;            # PRINT HELP IN TERMINAL
    d) daemon_flag=true ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done


if $daemon_flag ; then
    if [[ $(pgrep -f "clipboard_treater.sh -d" | wc -l) -ge 3 ]]; then
        $HOME/stuf/scripts/notification_wrapper.sh "$( pkill -o -f -e "clipboard_treater.sh -d" )" "CLIPTREAT"
    else
        treater_daemon </dev/null >/dev/null 2>&1 & disown
        $HOME/stuf/scripts/notification_wrapper.sh "$(pgrep -f "clipboard_treater.sh -d" )" "CLIPTREAT"
    fi
    exit
else 
    xclip -o -sel clip | sed -r "s|$|\x0f|g" | tr '\n' ' ' |  sed -r "s|-\x0f ||g; s|\x0f||g" | tr -s ' ' | xclip -sel clip
fi