#!/bin/bash


#MPV WINDOW / SOME OTHER OUTPUT
#pactl list sink-inputs | grep -E "^\s*Sink\ Input\ \#|^\s*media\.name\ \=\ " | tac | grep -A 1 -E "^\s*media\.name\ \=\ .*Onii.*" | grep -oP "Sink\ Input\ \#\K[0-9]+"

#SINK
#pacmd list-sinks | grep -E "^\s*name:|^\s*module:" | grep -A 1 -E "^\s*name: <CombinedDiscordSink>" | grep -oP "module: \K[0-9]+"

#########################     VARIABLES     #########################

SHORTCUTS=(
    'FUNCTION              |     TERMINAL EQUIVALENT                  |     RECOMMENDED KEYBIND'
    '------------------------------------------------------------------------------------------'
    'Change Sink           |     minivac.sh                           |     Ctrl+Shift+F7'
    'Load Sinks            |     minivac.sh -l                        |     -'
    'Unload Sinks          |     minivac.sh -u                        |     -'
    'Notify-send Sinks     |     minivac.sh -n                        |     F7'
    'Reset Sinks           |     minivac.sh -r                        |     Shift+F7'
)

DMENU_APPEARANCE="mononoki;11;#191919;#AAAAAA;#890089;#FFFFFF;Select Input:"

for i in {1..7}
do
   declare "dm$i=$(echo $DMENU_APPEARANCE | cut -f$i -d';')"     # CONVERT DMENU APPEARANCE STRIP INTO SEPARATE PARAMETERS
done

mapfile -t INPUTS < <( pactl list sink-inputs | grep -B 30 -A 10 "application.process.binary" | grep "Sink Input\|application\.name\|media\.name" | grep -B 2 "application\.name" | sed -r "/--/d; s|Sink\ Input\ ||g; s|[[:space:]]*application\.name\ \=|\~|g; s|[[:space:]]*media\.name\ \=\ |\~\ |g" | paste -sd '  \n' )

mapfile -t SINKS < <( pactl list sinks | grep -A 3 "Sink #" | grep "Sink #\|Name:\|Description:" | sed -r "s|[[:space:]]*Name:\ |\~ |g; s|[[:space:]]*Description:\ |\~\ |g" | paste -sd '  \n' )

#########################     HELPER FUNCTIONS     #########################

treat_inputs () {
    i=0
    for INPUT in "${INPUTS[@]}"
    do
        SINK=$( pactl list sink-inputs | grep -A 5 "$( echo $INPUT | sed -r "s| .*||g" )" | grep "Sink:")
        SINK_TRANSLATED=$( pactl list sinks | grep -A 3 "$( echo $SINK | sed -r 's|: | #|g')" | grep "Description" | sed -r "s|.*Description: ||g" )
        INPUTS[i]=$( echo "$INPUT -> $SINK_TRANSLATED" )
        ((i++))
    done
}

load_sinks () {
    if [[ -z "$(pactl list short modules | grep "DiscordSink")" ]]; then
        pactl load-module module-null-sink sink_name=VirtualDiscordSink
        pactl load-module module-loopback source=alsa_input.usb-C-Media_Electronics_Inc._YMC_1040-00.mono-fallback sink=VirtualDiscordSink
        pactl load-module module-combine-sink slaves=VirtualDiscordSink,alsa_output.pci-0000_00_1b.0.analog-stereo sink_name=CombinedDiscordSink
    else
        echo -e "\nSinks already loaded."
    fi
}

unload_sinks () {
    read -r -p "Are you sure? [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        pactl list short modules | grep "DiscordSink" | cut -f1 | xargs -L1 pactl unload-module
        echo -e "\nSinks unloaded."
    else
        echo -e "\nSink unloading aborted."
    fi
}

configure_mic () {
    MIC_NAME=$( pactl list source-outputs | grep -B 18 "WEBRTC VoiceEngine" | grep "Source Output #" | sed -r "s|^.*#||g" )
    MIC_SOURCE=$( pactl list source-outputs | grep -B 18 "WEBRTC VoiceEngine" | grep "Source:" | sed -r "s|^.*:\ ||g" )
    SINK_SOURCE=$( pactl list sources | grep -B 3 "VirtualDiscordSink.monitor" | grep "Source #" | sed -r "s|^.*#||g" )
    [[ "$MIC_SOURCE" -ne "$SINK_SOURCE" ]] && pactl move-source-output "$MIC_NAME" "VirtualDiscordSink.monitor" && $HOME/stuf/scripts/notification_wrapper.sh "\nMICROPHONE\nHAS BEEN MOVED TO SINK\n$SINK_SOURCE" "MINIVAC"
}

reset_sinks () {
    echo -e "Yes\nNo" \
    | dmenu -fn "$([[ $(fc-match "$dm1" | grep "$dm1") ]] && fc-match -f %{family} "$dm1" || fc-match -f %{family} mono)-$dm2" -l 10 -i -nb "$dm3" -nf "$dm4" -sb "#900D09" -sf "$dm6" -p "Reset all sinks?" \
    | grep "Yes" &> /dev/null && for INPUT in "${INPUTS[@]}"; do pactl move-sink-input "$(echo $INPUT | awk -F' ~ ' '{print $1}' | sed "s|#||")" "alsa_output.pci-0000_00_1b.0.analog-stereo"; done \
    && $HOME/stuf/scripts/notification_wrapper.sh "\nALL SINKS HAVE BEEN RESET" "MINIVAC"
}

notify_sinks () {
    treat_inputs
    $HOME/stuf/scripts/notification_wrapper.sh "\nLIST OF CURRENT MAPPINGS\n$(for INPUT in "${INPUTS[@]}"; do echo "\n$INPUT"; done)" "MINIVAC"
}

change_sink () {
    treat_inputs
    CHOICE_INPUT=$( echo "$(for INPUT in "${INPUTS[@]}"; do echo $INPUT; done)" | uniq | dmenu -fn "$([[ $(fc-match "$dm1" | grep "$dm1") ]] && fc-match -f %{family} "$dm1" || fc-match -f %{family} mono)-$dm2" -l 10 -i -nb "$dm3" -nf "$dm4" -sb "$dm5" -sf "$dm6" -p "$dm7" )
    CHI_COMMAND=$(echo $CHOICE_INPUT | awk -F' ~ ' '{print $1}' | sed "s|#||")
    CHI_NOTIFY=$(echo $CHOICE_INPUT | awk -F' ~ ' '{print $2}' )

    [[ -n $CHI_COMMAND ]] && CHOICE_SINK=$( echo "$(for SINK in "${SINKS[@]}"; do echo $SINK; done)" | uniq | dmenu -fn "$([[ $(fc-match "$dm1" | grep "$dm1") ]] && fc-match -f %{family} "$dm1" || fc-match -f %{family} mono)-$dm2" -l 10 -i -nb "$dm3" -nf "$dm4" -sb "$dm5" -sf "$dm6" -p "Select Sink:" )
    CHS_COMMAND=$(echo $CHOICE_SINK | awk -F' ~ ' '{print $2}' )
    CHS_NOTIFY=$(echo $CHOICE_SINK | awk -F' ~ ' '{print $3}' )

    [[ -n $CHI_COMMAND && -n $CHS_COMMAND ]] && pactl move-sink-input "$CHI_COMMAND" "$CHS_COMMAND" && $HOME/stuf/scripts/notification_wrapper.sh "\nSOURCE\n$CHI_NOTIFY\nHAS BEEN MOVED TO SINK\n$CHS_NOTIFY" "MINIVAC"
}

#########################     EXECUTION     #########################

# [[ -z $( grep -E "^alsa_output.pci-0000_03_04.0.analog-stereo$" $HOME/.config/pulse/* ) || -z $( grep -E "^alsa_input.pci-0000_03_04.0.iec958-stereo$" $HOME/.config/pulse/* ) ]] \
# && $HOME/stuf/scripts/notification_wrapper.sh "\nSYSTEM CHANGE DETECTED, TERMINATING PROGRAM" "MINIVAC" && exit

load_sinks
configure_mic

while getopts "hlunr" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-n notify-send sinks] [-l load sinks] [-u unload sinks] [-r reset sinks]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;        # PRINT HELP IN TERMINAL
    l) load_sinks; exit ;;                                                                                                                                                                          # LOAD ALL SINKS
    u) unload_sinks; exit ;;                                                                                                                                                                        # UNLOAD ALL SINKS
    n) notify_sinks; exit ;;                                                                                                                                                                        # LIST ALL SINKS VIA WRAPPER
    r) reset_sinks; exit ;;                                                                                                                                                                         # RESET ALL SINKS
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done

change_sink

# pacmd load-module module-loopback source=MICROPHONE_SOURCE sink=Virtual
# alsa_input.usb-C-Media_Electronics_Inc._YMC_1040-00.mono-fallback
# pacmd load-module module-combine-sink slaves=Virtual,SOUNDCARD_SINK
# alsa_output.pci-0000_03_04.0.analog-stereo
# set mpv playback to simultaneous output to null output, CMI... 
# set recording to monitor of null output




# pactl list sinks -> Sink #1
# pactl list sink-inputs -> Sink: 1

# make these functions: init/uninit (the things you already have), list active sinks, open sink toggle menu, reset sinks
# make the init spawn a daemon that checks and notifies if there are any open sinks left, make uninit kill it 