#!/bin/bash
#  .___                 __         .__  .__
#  |   | ____   _______/  |______  |  | |  |
#  |   |/    \ /  ___/\   __\__  \ |  | |  |
#  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
#  |___|___|  /____  > |__| (____  /____/____/
#           \/     \/            \/
#  ____ ___            .___       __
# |    |   \______   __| _/____ _/  |_  ____   ______
# |    |   /\____ \ / __ |\__  \\   __\/ __ \ /  ___/
# |    |  / |  |_> > /_/ | / __ \|  | \  ___/ \___ \
# |______/  |   __/\____ |(____  /__|  \___  >____  >
#          |__|        \/     \/          \/     \/
#
sleep 1
clear

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" --gum 2>/dev/null || true
if declare -F gum_apply_matugen_theme >/dev/null 2>&1; then
    gum_apply_matugen_theme
elif [[ -f "$HOME/.cache/matugen/gum.env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cache/matugen/gum.env"
fi

install_platform="$(cat ~/.config/hyprgruv/scripts/platform.sh)"

toilet -f graffiti Updates | lsd-print

echo

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------
if gum confirm "DO YOU WANT TO START THE UPDATE NOW?"; then
    echo
    echo ":: Update started." | lsd-print
elif [ $? -eq 130 ]; then
    exit 130
else
    echo
    echo ":: Update canceled." | lsd-print
    exit 1
fi

# Check if platform is supported
case $install_platform in
arch)
    aur_helper="$(cat ~/.config/hyprgruv/scripts/aur.sh)"

    _isInstalledAUR() {
        package="$1"
        check="$($aur_helper -Qs --color always "${package}" | grep "local" | grep "${package} ")"
        if [ -n "${check}" ]; then
            echo 0 #'0' means 'true' in Bash
            return #true
        fi
        echo 1 #'1' means 'false' in Bash
        return #false
    }

    if [[ $(_isInstalledAUR "timeshift") == "0" ]]; then
        echo
        if [[ -f /etc/hyprgruv/snapshots.env ]]; then
            # shellcheck source=/dev/null
            source /etc/hyprgruv/snapshots.env
            if [[ "${HYPRGRUV_LAYER2:-0}" == "1" ]]; then
                if findmnt "${HYPRGRUV_BACKUP_MOUNT:-/mnt/backup-ssd}" >/dev/null 2>&1; then
                    echo ":: Off-disk replica will run after this upgrade (${HYPRGRUV_BACKUP_MOUNT})" | lsd-print
                else
                    echo ":: Off-disk replica configured but ${HYPRGRUV_BACKUP_MOUNT:-/mnt/backup-ssd} is not mounted" | lsd-print
                fi
                echo
            fi
        fi
        if gum confirm "DO YOU WANT TO CREATE A SNAPSHOT?"; then
            echo
            c=$(gum input --placeholder "Enter a comment for the snapshot...")
            sudo timeshift --create --comments "$c"
            sudo timeshift --list
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            echo ":: DONE. Snapshot $c created!"
            echo
        elif [ $? -eq 130 ]; then
            echo ":: Snapshot skipped." | lsd-print
            exit 130
        else
            echo ":: Snapshot skipped." | lsd-print
        fi
        echo
    fi

    # Held AUR packages (see ~/.config/yay/pacman.conf IgnorePkg) stay installed
    # but are skipped so rebuild-loop -git packages do not re-download every -Syu.
    if [[ -f "$HOME/.config/yay/pacman.conf" ]]; then
        held=$(awk '/^[[:space:]]*IgnorePkg[[:space:]]*=/ {
            sub(/^[^=]*=/, "")
            print
        }' "$HOME/.config/yay/pacman.conf" | xargs)
        if [[ -n "$held" ]]; then
            echo ":: Skipping held packages: $held" | lsd-print
            echo
        fi
    fi

    $aur_helper

    if [[ $(_isInstalledAUR "flatpak") == "0" ]]; then
        flatpak upgrade
    fi
    ;;
fedora)
    sudo dnf upgrade
    ;;
*)
    echo ":: ERROR - Platform not supported" | lsd-print
    echo "Press [ENTER] to close."
    read
    ;;
esac

bash "${HYPRGRUV_DIR:-$HOME/.hyprgruv}/lib/scripts/system-maintain-remind.sh" --clear 2>/dev/null || true
notify-send "Update complete" | lsd-print
echo
echo ":: Update complete" | lsd-print
echo
echo
echo "Press [ENTER] to close." | lsd-print
read
