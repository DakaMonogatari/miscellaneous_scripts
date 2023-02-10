#!/bin/bash

ROFI_THEME="BernGray"
SCROTDIR="$HOME/Desktop"
SCROTPROGRAM="gimp"
SCROTFORMAT="Screenshot_$( date -u +%Y-%m-%d_%H-%M-%S )"
SCROTGEOMETRY="--single-screen"
DMENU_APPEARANCE="mononoki;11;#191919;#AAAAAA;#CC6600;#FFFFFF;Choose action:"

SHORTCUTS=(
    'FUNCTION                             |     TERMINAL EQUIVALENT     |     RECOMMENDED KEYBIND'
    '--------------------------------------------------------------------------------------------'
    'Take screenshot of entire screen     |     hackshot.sh             |     Shift+PrintScr'
    'Take screenshot of selected region   |     hackshot.sh -r          |     PrintScr'
    'Take screenshot of active window     |     hackshot.sh -w          |     Alt+PrintScr'
)

while getopts "hrw" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-d toggle daemon] [-s select]\n\nSuggested Keyboard Shortcuts:\n"; printf '%s\n' "${SHORTCUTS[@]}";  exit ;;            # PRINT HELP IN TERMINAL
    r) SCROTGEOMETRY="-g $( hacksaw 2>&1 )" ;;
    w) SCROTGEOMETRY="-g $( xdotool getwindowgeometry $(xdotool getactivewindow) | grep -o -E "[0-9]+(,|x)[0-9]+" | tac | sed -r "s|([0-9]+),([0-9]+)|+\1+\2|g" | tr -d "\n" )" ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done

[[ -n $( echo "$SCROTGEOMETRY" | grep "Error" ) ]] && exit

for i in {1..7}
do
   declare "dm$i=$(echo $DMENU_APPEARANCE | cut -f$i -d';')"     # CONVERT DMENU APPEARANCE STRIP INTO SEPARATE PARAMETERS
done

shotgun $SCROTGEOMETRY "/tmp/hackshot_temp.png"

CHOICE=$(echo -e "1. Save to $SCROTDIR\n2. Copy to clipboard\n3. Open with $SCROTPROGRAM\n4. Abort" \
| rofi -dmenu -i -no-custom -p "" -theme "$ROFI_THEME" -async-pre-read 3 -no-click-to-exit )

echo "$CHOICE" | grep "^1" &> /dev/null

if [[ -n $( echo "$CHOICE" | grep "^1" ) ]]; then
    cp "/tmp/hackshot_temp.png" "$SCROTDIR/$SCROTFORMAT.png" && rm "/tmp/hackshot_temp.png"
elif [[ -n $( echo "$CHOICE" | grep "^2" ) ]]; then
    xclip -selection clipboard -t image/png -i "/tmp/hackshot_temp.png" && rm "/tmp/hackshot_temp.png"
elif [[ -n $( echo "$CHOICE" | grep "^3" ) ]]; then
    nohup "$SCROTPROGRAM" "/tmp/hackshot_temp.png" >/dev/null 2>&1 && rm "/tmp/hackshot_temp.png" &
else
    rm "/tmp/hackshot_temp.png"
fi

# IT CAN'T BE JUST ONE RM AT THE END BECAUSE OF NOHUP &