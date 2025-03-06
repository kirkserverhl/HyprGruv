#!/bin/bash
#    ___ ___                      .__    .___.__
#   /   |   \ ___.__._____________|__| __| _/|  |   ____
#  /    ~    <   |  |\____ \_  __ \  |/ __ | |  | _/ __ \
#  \    Y    /\___  ||  |_> >  | \/  / /_/ | |  |_\  ___/
#   \___|_  / / ____||   __/|__|  |__\____ | |____/\___  >
#         \/  \/     |__|                 \/           \/

SERVICE="hypridle"
if [[ "$1" == "status" ]]; then
    sleep 1
    if pgrep -x "$SERVICE" >/dev/null ;then
        echo '{"text": "RUNNING", "class": "active", "tooltip": "Screen locking active\nLeft: Deactivate\nRight: Lock Screen"}'
    else
        echo '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "Screen locking deactivated\nLeft: Activate\nRight: Lock Screen"}'
    fi
fi
if [[ "$1" == "toggle" ]]; then
    if pgrep -x "$SERVICE" >/dev/null ;then
        killall hypridle
    else
        hypridle
    fi
fi
