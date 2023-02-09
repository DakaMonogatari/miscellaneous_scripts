#!/bin/bash


# xfconf-query -c xfce4-desktop -m
# Start monitoring channel "xfce4-desktop":
# set: /backdrop/screen0/monitorDP1/workspace0/last-image


# look into types of parentheses, $(( )) is math for example
# shuf is a thing
# also xargs -r is a thing


SHORTCUTS=(
    'FUNCTION              |     TERMINAL EQUIVALENT                  |     RECOMMENDED KEYBIND'
    '------------------------------------------------------------------------------------------'
    'Randomize Pape               |     pape.sh                              |     NUM-'
    'Notify-send Current Pape     |     pape.sh -n                           |     Ctrl+NUM-'
    'Toggle Pape Daemon           |     pape.sh -d                           |     Shift+NUM-'
    'Select Pape                  |     pape.sh -s                           |     Ctrl+Shift+NUM-'
)

current_desktop="/backdrop/screen0/monitorDVI-D-1/workspace0"

current_pape=$(xfconf-query -c xfce4-desktop -p $current_desktop/last-image) # INVALIDATE DUPLICATES

select_flag=false
daemon_flag=false # SET TOGGLER WITH KILLALL/SPAWN

PAPES="$HOME/papes"
PAPE=""
DMENU_APPEARANCE="mononoki;11;#191919;#AAAAAA;#CC6600;#FFFFFF;Choose your pape:"

#E0E04B
#AAAA00

function rotation_daemon { 
    while true; do 
        xfconf-query -c xfce4-desktop -p $current_desktop/last-image -s "$(find ~/papes -type f -iregex '.*\.\(bmp\|gif\|jpg\|jpeg\|png\)$' | sort -R | head -1)" 
        sleep 180
    done 
} 


while getopts "hnds" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-d toggle daemon] [-s select]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;            # PRINT HELP IN TERMINAL
    n) $HOME/stuf/scripts/notification_wrapper.sh "$( echo $current_pape | sed -r 's|^\/([^\/]+\/)+||g' )" "UNIVROT"; exit ;;     # NOTIFY-SEND QUEUE VIA MY OWN WRAPPER
    d) daemon_flag=true ;;
    s) select_flag=true ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done


for i in {1..7}
do
   declare "dm$i=$(echo $DMENU_APPEARANCE | cut -f$i -d';')"     # CONVERT DMENU APPEARANCE STRIP INTO SEPARATE PARAMETERS
done


if $daemon_flag ; then
    if [[ $(pgrep -f "universal_rotation.sh -d" | wc -l) -ge 3 ]]; then
         $HOME/stuf/scripts/notification_wrapper.sh "$( pkill -o -f -e "universal_rotation.sh -d" )" "UNIVROT"
    else
        rotation_daemon </dev/null >/dev/null 2>&1 & disown
        $HOME/stuf/scripts/notification_wrapper.sh "$(pgrep -f "universal_rotation.sh -d" )" "UNIVROT"  
    fi
    exit
fi


if $select_flag ; then

    # FIND EVERY DIRECTORY WITH AN AUDIO FILE IN IT AND PIPE IT INTO DMENU
    PAPE=$(find $PAPES -type f -iregex ".*\.\(bmp\|gif\|jpg\|jpeg\|png\)$" | grep -v "$current_pape" | sed -r "s|^\/([^\/]+\/)+||g" | sort --version-sort | uniq \
    | dmenu -fn "$([[ $(fc-match "$dm1" | grep "$dm1") ]] && fc-match -f %{family} "$dm1" || fc-match -f %{family} mono)-$dm2" -l 10 -i -nb "$dm3" -nf "$dm4" -sb "$dm5" -sf "$dm6" -p "$dm7" )   

    [[ -n $PAPE ]] && echo $PAPE | sed -r "s|'|\\\'|g" | xargs -I{} find $PAPES -type f -iname "{}" | head -n 1 \
    | xargs -I{} xfconf-query -c xfce4-desktop -p $current_desktop/last-image -s  "{}"


else
    
    # RANDOMIZE IT
    # find "$IE" -type f | sed "s|^.*\.\/|$IE|g" | grep -vf "$IE/exceptions.txt" | findimagedupes -R -p /bin/feh -t 95% -
    xfconf-query -c xfce4-desktop -p $current_desktop/last-image -s "$(find $PAPES -type f -iregex '.*\.\(bmp\|gif\|jpg\|jpeg\|png\)$' | sort -R | head -1)"
fi