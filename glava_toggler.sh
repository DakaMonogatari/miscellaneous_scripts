#/bin/bash

command="glava --desktop"
[[ -n $( pgrep -f "$command" ) ]] && pkill -f "$command" || nohup $command > /dev/null 2>&1 &


