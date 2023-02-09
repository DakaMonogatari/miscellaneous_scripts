#!/bin/bash

file_browser="thunar"
LINK=$1
TABFLAG=$2
# 0 = do nothing, 1 = store location in tablist, 2 = open tablist, 3 = 2+1
TYPE=""

# everything below this comment is horrible
[[ "$LINK" -eq 2 ]] && TABFLAG=2 && LINK="show_files"
[[ ! "$TABFLAG" =~ ^[0-3]$ ]] && TABFLAG=3
[[ -z "$LINK" || -z "$TABFLAG" ]] && echo "ERROR: NOT ENOUGH ARGUMENTS" && exit

declare -A TYPES=( ["mangasee123\.com"]="manga" ["mangadex\.org"]="manga" ["youtube\.com"]="clips" ["pixiv\.net"]="art" ["(danbooru\.)?donmai\.us"]="art")
declare -A LOCATIONS=( ["show_files"]="show_files" ["manga"]="$HOME/Downloads/Read or Die" ["art"]="$HOME/Tempsktop/gallery-dl" ["clips"]="$HOME/Downloads/Watch or Die/yt-dlp")

if [[ "$LINK" == "show_files" ]]; then
    TYPE="$LINK"
else
    for expr in "${!TYPES[@]}"; do
        [[ $LINK =~ ^http(s)?\:\/\/(www\.)?${expr}\/.*$ ]] && TYPE="${TYPES[$expr]}" && break   
    done
fi

[[ -z "$TYPE" ]] && echo "ERROR: LINK NOT PROPERLY PARSED" && exit

LOCATION="${LOCATIONS[$TYPE]}"
echo "LINK : $LINK, TYPE: $TYPE, LOCATION: $LOCATION"

case "$TYPE" in

"manga")
    gallery-dl `curl -Ls -o /dev/null -w %{url_effective} $LINK` --destination "$LOCATION" --ugoira-conv
    ;;

"art")
    gallery-dl `curl -Ls -o /dev/null -w %{url_effective} $LINK` --directory "$LOCATION" --ugoira-conv
    ;;

"clips")
    yt-dlp `curl -Ls -o /dev/null -w %{url_effective} $LINK` --paths "$LOCATION" --no-playlist
    ;;

"show_files")
    ;;

*)
    echo -n "ERROR: UNKNOWN TYPE"
    exit
    ;;

esac

[[ "$TABFLAG" -eq 0 ]] && exit

[[ "$TABFLAG" -eq 1 || "$TABFLAG" -eq 3 ]] && echo "$LOCATION" >> "/tmp/tablist.txt"

if [[ "$TABFLAG" -eq 2 || "$TABFLAG" -eq 3 ]]; then

    tabs=$( cat "/tmp/tablist.txt" | sort | uniq )
    # "$file_browser"

    IFS=$'\n'
    for tab in $tabs; do
        echo "TAB : $tab"

        wid=( $( xdotool search --desktop $( xdotool get_desktop ) --class "$file_browser" ) )
        lastwid=${wid[*]: -1}
        
        [[ -n "$lastwid" ]] && xdotool windowactivate --sync "$lastwid" key ctrl+t ctrl+l && xdotool type -delay 0 "$tab" && xdotool key Return || echo "ERROR: UNABLE TO OPEN FILE BROWSER"

    done
    unset IFS

    rm -f "/tmp/tablist.txt"
fi