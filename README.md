⚠️ Beta Version - Under Construction ⚠️
🚧 We Tried, We Warned Ya! 🚧This project is currently in BETA and under active development. Expect bugs, incomplete features, and potential crashes. Proceed with caution!  
🔥 For the best experience, we strongly recommend testing in a virtual machine with the following specs:  

Hypervisor: Any modern hypervisor (e.g., VirtualBox, VMware, Hyper-V)  
RAM: Minimum 4GB (8GB or more for smooth performance)  
Storage: At least 40GB free disk space

⚠️ Use at your own risk! We’re working hard to stabilize this project, but it’s a work in progress. Save your work frequently and consider running in an isolated environment to avoid any unexpected issues.  
💡 Feedback is welcome! If you encounter issues or have suggestions, please open an issue on this repository.  

🌟 Project Overview 🌟
HyprGruv 🚀
Hyprland Arch Linux featuring GruvBox!
Developed by Kirk Bass
Prerequisites:
Ventoy USB: Create a bootable USB using Ventoy and add the latest Arch Linux ISO to it.
Ensure Internet Access: Wired or wireless connection for installation.
Step 1: Install Arch Linux
Insert the Ventoy USB when the computer is off, turn on your device and you will choose the the Arch Linux ISO from the option menu.
Step 2: Install Arch Linux
Launch the Arch Linux guided installer with:
archinstall

Configure Installation:
Choose mirrors: US/backDisk Configuration: Partitioning, Use best-effort, choose drive, btrfs (or ext4), no btrfs subvolumes, use compression, no separate home partition/backSwap: enabledBootloader: grubChoose Hostname & PasswordCreate User Account, password, give sudo privileges / confirm & exitProfile: Type, Desktop, Hyprland, polkit / backAudio: PipewireNetwork Configuration: Use NetworkManagerAdditional Packages: firefoxChoose TimezoneInstall
Once installation is completed, use the following commands to reboot:
"Would you like to chroot?"    
no
shutdown --now

When the device is powered off, remove the Ventoy USB and restart the device.
Step 3: Login and Configuration
When Arch linux boots up you are greeted with the SDDM sign-on screen.
In the top left of the screen choose 'Hyprland' for session, not (uwsm-managed)
Use the user credentials created during the archinstall to login!
Open terminal with keybind:   
Win + Q


temporary, after install   Win + ENTER

Run the following string of commands Line:
sudo pacman -S git &&
git clone https://github.com/kirkserverhl/move ~/.hyprgruv &&
cd ~/.hyprgruv/
./install.sh

Tips
To move windows you can use: Win + Left Mouse**permanent bind, works before and after install
To close windows during install use:  Win + C** temporary bind, after install use:  Win + Q

be careful closing unnecessary windows during install

** After installing a list of keybinds is available using: ‘Win + K’ or by typing ‘keybinds’ in the terminal.
Post-Installation
The initial install will install the base packages and configure the zsh or bash shell configuration.  At this point the device will need to be rebooted for full configuration to take place.

Please note that full configuration will require a restart.

Open Firefox and navigate to 'about:config' in the URL bar.Set toolkit.legacyUserProfileCustomizations.stylesheets > TRUE
