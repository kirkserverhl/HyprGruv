# HyprGruv 🚀

Hyprland Arch Linux featuring GruvBox!

Developed by Kirk Bass

## Prerequisites:

Ventoy USB: Create a bootable USB using Ventoy and add the latest Arch Linux ISO to it.

Ensure Internet Access: Wired or wireless connection for installation.


## Step 1: Install Arch Linux

Insert the Ventoy USB when the computer is off, turn on your device and you will choose the the Arch Linux ISO from the option menu.

## Step 2: Install Arch Linux 

Launch the Arch Linux guided installer with:

```bash
archinstall
```

## Configure Installation:

Choose mirrors: US / back
Disk Configuration: Partitioning, Use best-effort, choose drive, btrfs (or ext4), no btrfs subvolumes, use compression, no separate home partition / back
Swap: enabled
Bootloader: grub
Choose Hostname & Password
Create User Account, password, give sudo privileges / confirm & exit
Profile: Type, Desktop, Hyprland, polkit / back
Audio: Pipewire
Network Configuration: Use NetworkManager
Additional Packages: firefox
Choose Timezone
Install

Once installation is completed use the following commands to reboot:

"Would you like to chroot?"    

```sh
no
shutdown -–now
```

When the device is powered off remove the Ventoy usb and restart the device.



## Step 3: Login and Configuration

When Arch linux boots up you are greeted with the SDDM sign-on screen.

In top left of screen choose 'Hyprland' for session, not (uwsm-managed)

Use the user credentials created durring the archinstall to login!

Open terminal with keybind:   
```sh
Win + Q
```    
 > temporary, after install   Win + ENTER

Run the following string of commands Line:

```sh
sudo pacman -S git &&
git clone https://github.com/kirkserverhl/hyprgruv.git ~/.hyprgruv &&
cd ~/.hyprgruv/
./install.sh
```

## Tips

To move windows you can use: Win + Left Mouse
**permanent bind, works before and after install

To close windows during install use:  Win + C
** temporary bind, after install use:  Win + Q

> be careful closing unnecessary windows during install

** after install a list of keydinds is available using:
 ‘Win + K’ or by typing ‘keybinds’ in the terminal.


## Post-Installation

The initial install will install the base packages and configure the zsh or bash shell configuration.  At this point the device will need to be rebooted for full configuration to take place.

 > Please note that full configuration will require a restart.

Open firefox and navigate to about:config in the URL bar. Set toolkit.legacyUserProfileCustomizations.stylesheets to true
