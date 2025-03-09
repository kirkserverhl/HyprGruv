#!/bin/bash
#!/bin/bash
#    ________                    ________           ___.
#   /  _____/______ __ _____  __/  _____/______ __ _\_ |__
#  /   \  __\_  __ \  |  \  \/ /   \  __\_  __ \  |  \ __ \
#  \    \_\  \  | \/  |  /\   /\    \_\  \  | \/  |  / \_\ \
#   \______  /__|  |____/  \_/  \______  /__|  |____/|___  /
#          \/                          \/                \/
#
################################################################ KMB2025 ##########
export SCRIPT_DIR CONFIG_DIR BACKUP_DIR

# Move Grub Package
sudo cp -r ~/.hyprgruv/assets/grub/tartarus /usr/share/grub/themes/tartarus

# Move Grub Config
sudo cp -r ~/.hyprgruv/assets/grub/grub /etc/default/grub

# Compile Grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
