#!/bin/sh

PRESET="$1"

if [[ $(ps -aux | grep -v grep | grep "input-remapper") ]]
then
        if [[ $(ps -aux | grep -v grep | grep "\[input-remapper-\]") ]]
        then
              input-remapper-control --command start --device "Microsoft X-Box One S pad" --preset "$PRESET"  
              $HOME/stuf/scripts/notification_wrapper.sh "\nController mapping ON" "KEYTOG"
        else
              input-remapper-control --command stop-all --device "Microsoft X-Box One S pad"
              $HOME/stuf/scripts/notification_wrapper.sh "\nController mapping OFF" "KEYTOG"
        fi

else
        nohup input-remapper-service >/dev/null 2>&1 &
        
        while [[ ! $(ps -aux | grep -v grep | grep "\[input-remapper-\]") ]]; do
            input-remapper-control --command start --device "Microsoft X-Box One S pad" --preset "$PRESET"  
            input-remapper-control --command stop-all --device "Microsoft X-Box One S pad"
        done

        $HOME/stuf/scripts/notification_wrapper.sh "\ninput-remapper-service started" "KEYTOG"
        #don't ask
fi


#IMPLEMENT KILLALL

#WHEN YOU FIX THE RIGHT TRIGGER, MOVE F TO IT, AND MAKE BOTTOM BUTTON ESC