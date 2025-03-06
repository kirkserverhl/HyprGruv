#!/bin/bash
#    ________                    ________           ___.
#   /  _____/______ __ _____  __/  _____/______ __ _\_ |__
#  /   \  __\_  __ \  |  \  \/ /   \  __\_  __ \  |  \ __ \
#  \    \_\  \  | \/  |  /\   /\    \_\  \  | \/  |  / \_\ \
#   \______  /__|  |____/  \_/  \______  /__|  |____/|___  /
#          \/                          \/                \/
#
################################################################ KMB2025 ##########


git clone https://github.com/AllJavi/tartarus-grub.git
cd tartarus-grub
sudo cp tartarus -r /usr/share/grub/themes/


sudo vim /etc/default/grub
# Change GRUB_THEME= to one of the following: Vimix tartarus starfield boo
#GRUB_THEME="/usr/share/grub/themes/<theme_name>/theme.txt"


sudo grub-mkconfig -o /boot/grub/grub.cfg

# It works, would like to offer the 5 plus tartus
