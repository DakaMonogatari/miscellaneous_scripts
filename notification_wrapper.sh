#!/bin/bash

# echo "This is $0"
# echo "This is \$BASH_SOURCE: $BASH_SOURCE"

export DISPLAY=":0.0" 
export XDG_RUNTIME_DIR=/run/user/$(id -u)

##------------------------------DEFAULT NOTIFICATION------------------------------##

FLAG=true
CALLER=$( ps -o comm= $PID )
SUMMARY="Default Notification - CALLER:$CALLER "
ICONS="$HOME/stuf/customization/icons"
ICON="$ICONS/ENE.png"
TIME=5000

##------------------------------ECHO NOTIFICATION------------------------------##

#DOESN'T WORK, FIGURE OUT WHY ONE DAY

[[ $(echo $CALLER | grep "echo") ]] && SUMMARY="Echo" && DESCRIPTION=$1 && ICON="$ICONS/ENE.png"

##------------------------------RSYNC NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep "universal_rsync") && "$2" =~ "URSYNC" ]] && SUMMARY="Universal Rsync" && DESCRIPTION=$1 && TIME=15000 && [[ "$2" == "URSYNCSUCC" ]] && ICON="$ICONS/OS/T_JunoWOW.png" || ICON="$ICONS/OS/T_JunoZoom.png"

##------------------------------KEYMAPPER NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep "keymap_toggler" && "$2" == "KEYTOG" ) ]] && SUMMARY="Key Mapper" && DESCRIPTION=$1 && ICON="$ICONS/erikahorni.png"

##------------------------------DISCORD MEDIA STREAMER NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep "minivac" && "$2" == "MINIVAC") ]] && SUMMARY="MiniVAC" && DESCRIPTION=$1 && TIME=15000 && ICON="$ICONS/holic.gif"

##------------------------------VOICE CHANGER NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep "voice_changer") && "$2" == "VOICHANG" ]] && SUMMARY="Voice Changer" && DESCRIPTION=$1 && TIME=15000 && ICON="$ICONS/holic.gif"

##------------------------------NEWSBOAT NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep newsboat) ]] && SUMMARY="Newsboat" && DESCRIPTION=$1 && ICON="$ICONS/kizukawablob.png"


##------------------------------CMUS NOTIFICATION------------------------------##

if [[ $(echo $CALLER | grep cmus) ]]; then
    
    SUMMARY="Cmus"


    # ARGUMENT PROCESSING

    while test $# -ge 2
    do
        eval _$1='$2'
        shift
        shift
    done


    # ARGUMENT FORMATTING
    ### for some reason processing $_duration of certain files completely erases all the other args,
    ### so the three lines below have to be above it
    ### echo $@ if you don't believe me


    # ${} Parameter expansion
    # $() Command substitution
    
    [[ $_artist == "" ]] && _artist="N/A"
    [[ $_title == "" ]] && [[ ${_title=$_file} == "" ]] && _title="N/A"
    [[ $_status != *playing* ]] && FLAG=0

    # DURATION FORMATTING

    if [[ $_duration != "" ]]; then
        h=$(($_duration / 3600))
        m=$(($_duration % 3600))

        duration=""
        test $h -gt 0 && dur="$h:"
        duration="$dur$(printf '%02d:%02d' $(($m / 60)) $(($m % 60)))"
    else
        duration="N/A"
    fi


    # DESCRIPTION FORMATTING
    ICON="$ICONS/rikanom.png"
    DESCRIPTION="Now playing: "$_title" ["$duration"]\nArtist: "$_artist
fi

##------------------------------PLAY SCRIPT QUEUE NOTIFICATION------------------------------##

[[ $(echo $CALLER | grep universal_play) && "$2" == "UNIVPLAY" ]] && SUMMARY="Songs currently in queue:" && DESCRIPTION=$1 && ICON="$ICONS/rikanom.png"

##------------------------------ROTATION DAEMON NOTIFICATION------------------------------##

if [[ $(echo $CALLER | grep universal_rotat) && "$2" == "UNIVROT" ]]; then

    OUTPUT=$1
    ICON="$ICONS/tenshi1.png"
    SUMMARY="Pape"
    DESCRIPTION=""
    [[ $(echo "$OUTPUT" | grep -i "killed") ]] && DESCRIPTION="Pape rotation daemon killed (PID: " || DESCRIPTION="Pape rotation daemon spawned (PID: " && DESCRIPTION="${DESCRIPTION}$(echo "$OUTPUT" | head -n 1 | sed -r "s/[^0-9]*//g"))"
    [[ $(echo "$OUTPUT" | grep -i "bmp\|gif\|jpg\|jpeg\|png") ]] && DESCRIPTION="Current Pape: $OUTPUT"

fi

##------------------------------CLIPBOARD TREATER DAEMON NOTIFICATION------------------------------##

if [[ $(echo $CALLER | grep clipboard_treat) && "$2" == "CLIPTREAT" ]]; then

    OUTPUT=$1
    ICON="$ICONS/tenshi2.png"
    SUMMARY="Clipboard Treater $2"
    DESCRIPTION=""
    [[ $(echo "$OUTPUT" | grep -i "killed") ]] && DESCRIPTION="Clipboard treater daemon killed (PID: " || DESCRIPTION="Clipboard treater daemon spawned (PID: " && DESCRIPTION="${DESCRIPTION}$(echo "$OUTPUT" | head -n 1 | sed -r "s/[^0-9]*//g"))"

fi


##------------------------------THE ACTUAL NOTIFICATION------------------------------##

#notify-send -u low -t 5000 -i ~/stuf/tsubasatwinneofetch.jpg "$SUMMARY" "$DESCRIPTION"
#notify-send -u low -t 5000 -i ~/stuf/red.jpg "$SUMMARY" "$1"
$FLAG && notify-send -u low -t $TIME -i $ICON "$SUMMARY" "$DESCRIPTION"

##------------------------------MAKE NOTIFICATIONS FOR OTHER SCRIPTS------------------------------##


