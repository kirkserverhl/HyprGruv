#!/bin/bash

# Ensure dependencies are installed
sudo pacman -S smbclient cifs-utils

# Create mount points
sudo mkdir -p /mnt/jel1 
sudo mkdir -p /mnt/jel1 

# Mount SMB Jellyfin Shares to mount points
sudo mount.cifs //192.168.0.157/jel1 /mnt/jel1 -o username=kirk,password=123456
sudo mount.cifs //192.168.0.157/jel2 /mnt/jel2 -o username=kirk,password=123456
sudo mount.cifs //192.168.0.157/jel3 /mnt/jel3 -o username=kirk,password=123456

echo " 󱛟  Jellyfin Drives Mounted "
