#!/bin/bash
#  _________ .__  .__       .__    .__          __   
#  \_   ___ \|  | |__|_____ |  |__ |__| _______/  |_ 
#  /    \  \/|  | |  \____ \|  |  \|  |/  ___/\   __\
#  \     \___|  |_|  |  |_> >   Y  \  |\___ \  |  |  
#   \______  /____/__|   __/|___|  /__/____  > |__|  
#          \/        |__|        \/        \/        
#
case $1 in
    d) cliphist list | rofi -dmenu -replace -config ~/.config/rofi/config-cliphist.rasi | cliphist delete
       ;;

    w) if [ `echo -e "Clear\nCancel" | rofi -dmenu -config ~/.config/rofi/config-short.rasi` == "Clear" ] ; then
            cliphist wipe
       fi
       ;;

    *) cliphist list | rofi -dmenu -replace -config ~/.config/rofi/config-cliphist.rasi | cliphist decode | wl-copy
       ;;
esac
