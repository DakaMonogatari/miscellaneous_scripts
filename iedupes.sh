#!/bin/bash

export IE="$(pwd)"
export file="exceptions.txt"

( [ -e "$file" ] || touch "$file" ) && [ ! -w "$file" ] && echo cannot write to $file && exit 1

re='^Minimal|VerySmall|Small|Medium|High|VeryHigh$'

declare SIMILARITY

while read -p "Enter similarity preset [Default: Small; Allowed: Minimal, VerySmall, Small, Medium, High, VeryHigh]: " SIMILARITY; do    

    SIMILARITY=${SIMILARITY:-"Small"}

    if ! [[ $SIMILARITY =~ $re ]]; then
        echo "error: Invalid input" >&2; continue
    fi

    break
done

mapfile -t matches < <( czkawka_cli image -d "$IE" -s "$SIMILARITY" | sed -r "s| \- [0-9]*x[0-9]* \- [0-9]*\.[0-9]* [KMGTP]iB \- [a-zA-Z ]*$||g ; s|Found [0-9]+ images which have similar friends||g " | head -n -5 \
| awk -v RS=  '{$1=$1; t=!/\//; if(NR>1 && t) print ""; print; if(t) print ""}' )

count=0

for match in "${matches[@]}"
do
    matches[$count]=$( echo "$match" | sed -r "s|\ \/|\n\/|g" | sort | tr '\n' ' ' | sed -r "s| $|\n|" )
    ((count++))
done


printf '%s\n' "${matches[@]}" | grep -vf "$IE/$file" | while IFS= read -r line
do
echo -e "$line" | sed -r "s|\ \/home\/|\n\/home\/|g" | /bin/feh --info "printf '%S%5s%wx%h'" --zoom max --scale-down -g 1280x720 -B black -d --action1 "gio trash %F" --action2 "cat %L | sed -r 's|^\.|$(pwd)|g' | sort | tr '\n' ' ' | paste -s -d ' ' | sed 's| $||g' >> \"$IE/$file\"" -f -
done

sort -u "$IE/$file" -o "$IE/$file"

rm /tmp/feh_*_filelist

# EVERYTHING IS HOW IT'S SUPPOSED TO BE, THERE CAN BE NO IMPROVEMENTS, NOTHING ELSE WORKED
# | sed -e "s|\(\/.*\)|\"\1\"|g"
# ; s|\ |\\\ |g

unset IE
unset file

#THIS IS BEST PRACTICE FOR ENVIRONMENT VARIABLES, CONSIDER CORRECTING ~/stuf STUFF
# -t 95% WORKS FOR ELIMINATING THE CHAFF, BUT IT MIGHT MISS SOME

#feh . --action1 "cat %L | sed -r 's|^\.|$(pwd)|g' | sort | tr '\n' ' ' "
#czkawka_cli image -d "/home/jay/Tempsktop" -s "High" | sed -r "s| \- [0-9]*x[0-9]* \- [0-9]*\.[0-9]* [KMGTP]iB \- [a-zA-Z ]*$||g ; s|Found [0-9]+ images which have similar friends||g " | head -n -5 | awk -v RS=  '{$1=$1; t=!/\//; if(NR>1 && t) print ""; print; if(t) print ""}' | xargs -n 1| sort | xargs


# IF IT WORKS WITH QUOTES, ADD QUOTES

