#!/bin/bash

function alarm_daemon { 
    while true; do 
        # NOISE
        sleep $(($RANDOM % 1200 + 1500))
    done 
}


if [[ $(pgrep -f "learning_alarm.sh" | wc -l) -ge 3 ]]; then
    $HOME/stuf/scripts/notification_wrapper.sh "$( pkill -o -f -e "learning_alarm.sh" )" "RANDALRM"
else
    alarm_daemon </dev/null >/dev/null 2>&1 & disown
    $HOME/stuf/scripts/notification_wrapper.sh "$(pgrep -f "learning_alarm.sh" )" "RANDALRM"  
fi