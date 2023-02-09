#!/bin/bash

OLDIFS=$IFS
IFS=$'\n'       # make newlines the only separator

declare -a exprs=("\\\"([^\\\"]+)\\\"|“\1”" "\?|？")
sedexpr=""
grepexpr="("

for i in "${exprs[@]}"; do
	sedexpr+=$(echo "s|"$i"|g; ")
	grepexpr+="$(echo $i | cut -d '|' -f 1)|"
done

sedexpr="${sedexpr::-1}"
grepexpr="${grepexpr::-1})"

for path in $(find "$(pwd)" -type f); do
	file=$( basename "$path" )
	[[ ! $( echo "$file" | grep -E "$grepexpr" 2>/dev/null ) ]] && continue
	
	while true; do
		question="The following command is about to run: $ mv \"$file\" \"$(echo "$file" | sed -r "$sedexpr")\""$'\n'"Is this okay [y/n]? "
		read -p "$question" yn
		case $yn in
		    [Yy]* ) mv "$file" "$(echo "$file" | sed -r "$sedexpr")"; break;;
		    [Nn]* ) break;;
		    * ) echo "Please answer yes or no.";;
		esac
	done
	
done

IFS=$OLDIFS
