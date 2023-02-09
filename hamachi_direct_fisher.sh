#!/bin/bash

while true; do
    HOST=$( hamachi list | grep "\[.*\]" | sed -r 's|^.*owner\: ||g; s|[\(\)]||g' | awk '{print $2, " ", $1}' )
    [[ -n "$HOST" ]] && break
    hamachi login
    sleep 5
done

echo "Attempting to establish direct connection with: $HOST"

while true; do

    CONNECTION=$( hamachi list | grep "$HOST"  | sed -r "s|^.*(\ ){25}||g; s|(\ ){2,3}.*||g" )
    echo "Connection: $CONNECTION"

    [[ "$CONNECTION" = "via server" ]] && sleep 5 && continue

    [[ "$CONNECTION" = "direct" ]] && break || ( hamachi logout && sleep 5 && hamachi login && sleep 5 )

done