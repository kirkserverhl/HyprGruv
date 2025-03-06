#!/bin/bash
##  Config.sh
##
clear ####################################################### kb
#################################################################
RESET="\e[0m"                # Reset  ##  Notes:
GREEN="\e[38;2;142;192;124m" # 8ec07c ##
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215
;153;33m"                # d79921 ##
RED="\e[38;2;204;36;29m" # cc241d ##
GRAY="\e[38;2;60;56;54m" # 3c3836 ##
BOLD="\e[1m"             # Bold   ##
clear                    #####################################

# Function to print status messages
log_status() {
  echo -e "${CYAN}[INFO]${RESET} $1"
}
# Function to print success messages
log_success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}
# Function to print warning messages
log_warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}
# Function to print error messages
log_error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# Function to display headers
display_header() {
  figlet -f ~/.fonts/Graffiti.flf "$1"
}

# Function to track actions and their completion state
track_action() {
  local action="$1"
  local status="$2" # "✔" for completed, "x" for not completed
  checklist+=("$action,$status")
}

# Initialize checklist
checklist=()

#### SDDM Configuration  ####

display_header "SDDM" | lsd-print
echo ""
read -rp "   🍬     Would you like to install Sugar-Candy SDDM theme  (y/n)  ? " # configure_sddm
echo ""
if [[ "$configure_sddm" =~ ^[Yy]$ ]]; then
  if ~/.hyprgruv/setup/sddm_candy_install.sh; then
    track_action "SDDM setup"
    mark_completed "SDDM Setup"
  else
    mark_skipped "SDDM Setup"
  fi
else
  mark_skipped "SDDM Setup"
fi
clear

######## Monitors #########################

display_header "Monitors"
echo ""
read -rp "   🖥️    Would you like to configure monitor setup  (y/n)  ? " configure_monitor
echo ""
if [[ "$configure_monitor" =~ ^[Yy]$ ]]; then
  if ~/.hyprgruv/setup/monitor.sh; then
    track_action "Monitor setup"
    mark_completed "Monitor Setup"
  else
    mark_skipped "Monitor Setup"
  fi
else
  mark_skipped "Monitor Setup"
fi
clear

#######  GRUB Theme and Extra Packages ##########

display_header "GRUB"
echo ""
read -rp "  🪱    Would you like to configure GRUB theme & extra packages (y/n)? " configure_grub
echo ""
if [[ "$configure_grub" =~ ^[Yy]$ ]]; then
  if sudo -v; then                 # Checks if the user has sudo privileges
    sudo ~/.hyprgruv/setup/grub.sh # Run the script with sudo
    track_action "Grub Theme"
    mark_completed "Grub Theme"
  else
    echo "You need sudo privileges to configure the GRUB theme."
    mark_skipped "Grub Theme"
  fi
else
  mark_skipped "Grub Theme"
fi
clear

######  Editors Choice #######################

#display_header "Editors Choice"
#echo ""
#read -rp "  🫠    Would you like to install Editors Choice packages  (y/n) ? " editors_choice
#echo ""
#if [[ "$editors_choice" =~ ^[Yy]$ ]]; then
#  if ~/.hyprgruv/setup/editors_choice.sh; then
#    track_action "Editors Choice Packages"
#    mark_completed "Editors Choice Packages"
#  else
#    mark_skipped "Editors Choice Packages"
#  fi
#else
#  mark_skipped "Editors Choice Packages"
#fi
#clear

#########  Terminal Effects  ################

#display_header "Terminal Effects"
#echo ""
#read -rp "   🌈    Would you like to Beautify your Terminal  (y/n) ?   " terminal_effects
#if [[ "$terminal_effects" =~ ^[Yy]$ ]]; then
#  if ~/.hyprgruv/setup/term_fx.sh; then
#    track_action "Terminal Effects"
#    mark_completed "Terminal Effects"
#  else
#    mark_skipped "Terminal Effects"
#  fi
#else
#  mark_skipped "Terminal Effects"
#
#clear

###########  Cleanup  ####################

display_header "Cleanup" | lsd-print
echo ""
read -rp "  🧹    Would you like to perform a system cleanup  (y/n) ? " perform_cleanup
if [[ "$perform_cleanup" =~ ^[Yy]$ ]]; then
  if ~/scripts/cleanup.sh; then
    track_action "System cleanup"
    mark_completed "Cleanup"
  else
    mark_skipped "Cleanup"
  fi
else
  mark_skipped "Cleanup"
fi
clear

#### Confirmation Page ####

~/.hyprgruv/setup/finished.sh
