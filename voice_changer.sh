#!/bin/bash

set -e

MIC_NAME=""
MIC_SOURCE=""
SINK_SOURCE=""
SWAP_FLAG=0

function load_sinks ()
{
    if [[ -z "$(pactl list short modules | grep "VoiceChangerSink")" ]]; then
        pactl load-module module-null-sink sink_name=VoiceChangerSink
    else
        echo -e "\nSinks already loaded."
    fi
}

function configure_mic ()
{
    MIC_NAME=$( pactl list source-outputs | grep -B 17 "WEBRTC VoiceEngine" | grep "Source Output \#" | sed -r "s|^.*\#||g" )
    MIC_SOURCE=$( pactl list source-outputs | grep -B 17 "WEBRTC VoiceEngine" | grep "Source\:" | sed -r "s|^.*\:\ ||g" )
    SINK_SOURCE=$( pactl list sources | grep -B 3 "VoiceChangerSink.monitor" | grep "Source \#" | sed -r "s|^.*\#||g" )
    MIC_DEFAULT=$( pactl list sources | grep -B 3 "alsa_input.usb-C-Media_Electronics_Inc._YMC_1040-00.mono-fallback" | grep "Source \#" | sed -r "s|^.*\#||g" )
}

function toggle ()
{
    if [[ "$MIC_SOURCE" -ne "$SINK_SOURCE" ]]; then
        pactl move-source-output "$MIC_NAME" "VoiceChangerSink.monitor" && $HOME/stuf/scripts/notification_wrapper.sh "\nMICROPHONE\nHAS BEEN MOVED TO SINK\n$SINK_SOURCE" "VOICHANG"
    else
        pactl move-source-output "$MIC_NAME" "$MIC_DEFAULT" && $HOME/stuf/scripts/notification_wrapper.sh "\nMICROPHONE\nHAS BEEN MOVED TO SINK\n$MIC_DEFAULT" "VOICHANG"
    fi
}

function normal ()
{
    sox -t pulseaudio default -t pulseaudio VoiceChangerSink
}

function bladewolf ()
{
    if [[ $SWAP_FLAG -eq 1 || -z $( pgrep -f "sox" ) ]]; then
        pgrep -f "sox" >/dev/null 2>&1 && pkill -f "sox"
        while [[ -n $(pgrep -f "sox") ]]; do
            :
        done 
        nohup sh -c "sox -t pulseaudio default -p pitch -225 | sox - -m -t pulseaudio default -t pulseaudio VoiceChangerSink pitch +75 echo 0.4 0.8 40 0.8 gain +7.5 bass +25" >/dev/null 2>&1 &
    else
        echo -e "\nOne voice is already loaded and a swap wasn't explicitly requested."
    fi
}

function demonbot ()
{
    if [[ $SWAP_FLAG -eq 1 || -z $( pgrep -f "sox" ) ]]; then
        pgrep -f "sox" >/dev/null 2>&1 && pkill -f "sox"
        while [[ -n $(pgrep -f "sox") ]]; do
            :
        done 
        nohup sh -c "sox -t pulseaudio default -p pitch -225 | sox - -m -t pulseaudio default -t pulseaudio VoiceChangerSink pitch -75 echo 0.4 0.8 40 0.8 gain +7.5 bass +25" >/dev/null 2>&1 &
    else
        echo -e "\nOne voice is already loaded and a swap wasn't explicitly requested."
    fi
}

function looper ()
{
    # gain +7.5
    if [[ $SWAP_FLAG -eq 1 || -z $( pgrep -f "sox" ) ]]; then
        pgrep -f "sox" >/dev/null 2>&1 && pkill -f "sox"
        while [[ -n $(pgrep -f "sox") ]]; do
            :
        done 
        nohup sh -c "sox -t pulseaudio default -p pitch +15 | sox - -m -t pulseaudio default -t pulseaudio VoiceChangerSink pitch -15 echo 0.4 0.8 30 0.75 bass +25 treble +12" >/dev/null 2>&1 &
    else
        echo -e "\nOne voice is already loaded and a swap wasn't explicitly requested."
    fi
}

function unload_sinks ()
{
    read -r -p "Are you sure? [y/N] " response
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        pactl move-source-output "$MIC_NAME" "$MIC_DEFAULT" && $HOME/stuf/scripts/notification_wrapper.sh "\nMICROPHONE\nHAS BEEN MOVED TO SINK\n$MIC_DEFAULT" "VOICHANG"
        pgrep -f "sox" >/dev/null 2>&1 && pkill -f "sox"
        while [[ -n $(pgrep -f "sox") ]]; do
            :
        done        
        pactl list short modules | grep "VoiceChangerSink" | cut -f1 | xargs -L1 pactl unload-module
        echo -e "\nSinks unloaded."
    else
        echo -e "\nSink unloading aborted."
    fi
}

[[ -z $( grep -E "^alsa_output.pci-0000_03_04.0.analog-stereo$" $HOME/.config/pulse/* ) || -z $( grep -E "^alsa_input.pci-0000_03_04.0.iec958-stereo$" $HOME/.config/pulse/* ) ]] \
&& $HOME/stuf/scripts/notification_wrapper.sh "\nSYSTEM CHANGE DETECTED, TERMINATING PROGRAM" "VOICHANG" && exit

load_sinks
looper
configure_mic

while getopts "hlunrt" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-n notify-send sinks] [-l load sinks] [-u unload sinks] [-r reset sinks]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;        # PRINT HELP IN TERMINAL
    l) load_sinks; exit ;;                                                                                                                                                                          # LOAD ALL SINKS
    u) unload_sinks; exit ;;                                                                                                                                                                        # UNLOAD ALL SINKS
    # n) notify_sinks; exit ;;                                                                                                                                                                        # LIST ALL SINKS VIA WRAPPER
    # r) reset_sinks; exit ;;                                                                                                                                                                         # RESET ALL SINKS
    t) toggle; exit;;    
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done


#trap 'echo "penis"' SIGINFO
#trap cleanup EXIT
