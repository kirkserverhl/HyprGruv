#!/bin/bash

# Check if any instance of pomodorolm is running
if pgrep -x "pomodorolm" > /dev/null
then
    # If running, kill the existing instance(s)
    pkill -x "pomodorolm"
    echo "Closed existing pomodorolm instance(s)."
    sleep 1  # wait for a second before launching the new instance
fi

# Launch a new instance of pomodorolm
pomodorolm &
echo "Started a new pomodorolm instance."

