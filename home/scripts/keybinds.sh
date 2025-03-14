#!/bin/bash

# Configuration
ROFI_CONFIG="~/.config/rofi/config-compact.rasi"
KEYBIND_FILE="$HOME/.config/hypr/conf/keybindings/default.conf"

# Icon mapping for the alphabet
declare -A ALPHABET_ICONS=(
  [A]="󰯬" [B]="󰯯" [C]="󰯲" [D]="󰯵" [E]="󰯸" [F]="󰯻" [G]="󰾾" [H]=""
  [I]="󰰄" [J]="󰰇" [K]="󰰊" [L]="󰰍" [M]="󰰐" [N]="󰰓" [O]="󰰖" [P]="󰰙"
  [Q]="󰰜" [R]="󰰟" [S]="󰰢" [T]="󰰥" [U]="󰰨" [V]="󰰫" [W]="󰰮" [X]="󰰱"
  [Y]="󰰴" [Z]="󰰷" [1]="󰲠" [2]="󰲢" [3]="󰲤" [4]="󰲦" [5]="󰲨" [6]="󰲪"
  [7]="󰲬" [8]="󰲮" [9]="󰲰" [0]="󰎡"
)

# Icon mapping for directions
declare -A DIRECTION_ICONS=(
  [Left]="󰜱" [Up]="󰜴" [Down]="󰜷" [Right]="󰜮"
)

# Parse keybinds and generate case entries
parse_keybinds() {
  local keybinds_hint=""
  local case_entries=""
  local in_applications_section=false
  
  while IFS= read -r line; do
    # Check if we are in the Applications section
    if [[ "$line" =~ ^\#\ Applications ]]; then
      in_applications_section=true
      continue  # Skip the comment line itself
    fi

    # Check if we are still in the Applications section and parse accordingly
    if $in_applications_section; then
      if [[ "$line" =~ ^bind ]]; then
        # Extract key combination, command, and description
        local key_combination=$(echo "$line" | cut -d',' -f2 | xargs)
        local command=$(echo "$line" | cut -d',' -f4 | awk '{print $1}')
        local description=$(echo "$line" | awk -F'#' '{print $2}' | xargs)
        
        # Check for modifiers and append them to the display
        local modifier=""
        if [[ "$line" =~ CTRL ]]; then
          modifier="CTRL + "
        elif [[ "$line" =~ ALT ]]; then
          modifier="ALT + "
        elif [[ "$line" =~ SHIFT ]]; then
          modifier="SHIFT + "
        fi

        # Replace the key with the corresponding icon
        local key_icon="${ALPHABET_ICONS[$key_combination]}"
        key_icon="${key_icon:-${DIRECTION_ICONS[$key_combination]}}"
        key_icon="${key_icon:-$key_combination}" # Fallback to the key if no icon is found

        # Add to keybind hints
        keybinds_hint+="󰌓 ▏󰖳 + $modifier$key_icon                  $description\n"

        # Add to case entries
        case_entries+="\"$description\")\n  $command\n  ;;\n"
      fi
    fi

    # After applications section, append static content
    if $in_applications_section && [[ -z "$line" || "$line" =~ ^\#\ Windows ]]; then
      # Stop parsing applications section after a blank line or Windows section begins
      in_applications_section=false
    fi
  done < "$KEYBIND_FILE"

  # Add static sections to the keybinds
  keybinds_hint+="━━━━━━━━━━━━━━━━━ Utils ━━━━━━━━━━━━━━━━━━━━\n"
  keybinds_hint+="󰌓 ▏󰖳 + CTRL + Tab         List Opened Apps\n"
  keybinds_hint+="󰌓 ▏󰖳 + SHIFT + 󰯲          Open Clipboard History\n"
  keybinds_hint+="󰌓 ▏󰖳 + Print              Screenshot\n"
  keybinds_hint+="󰌓 ▏󰖳 + Shift + 󰰢          Screenshot\n"
  keybinds_hint+="󰌓 ▏󰖳 + CTRL + 󰰮           Select Wallpaper\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰘶 + 󰰮              Random Wallpaper\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰘶 + 󰰁              HyprShade (BlueFilter)\n"
  keybinds_hint+="━━━━━━━━━━━━━━━━━━ Windows ━━━━━━━━━━━━━━━━━━\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰰜                  Kill Active Window\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰯻                  Fullscreen\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰰢                  Toggle Split\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰰥                  Toggle Floating\n"
  keybinds_hint+="󰌓 ▏󰖳 + SHIFT + 󰰥          Toggle Group Float\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰯾                  Toggle Group\n"
  keybinds_hint+="󰌓 ▏ALT + 󰰴                Move Window    \n"
  keybinds_hint+="󰌓 ▏󰖳  + 󰜱 󰜴 󰜷 󰜮           Move Focus    \n"
  keybinds_hint+="󰌓 ▏󰖳  + 󰰁 󰍀 󰰊 󰰇           Move Focus    \n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰘶 + 󰜱 󰜴 󰜷 󰜮        Resize Window    \n"
  keybinds_hint+="━━━━━━━━━━━━━━━━━━ Workspaces ━━━━━━━━━━━━━━━━\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰲠-󰲰                Workspace 1-9\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰘶 + 󰲠-󰲰            Move Window To 1-9\n"
  keybinds_hint+="󰌓 ▏󰖳 + 󰰊                  This Menu\n"
  keybinds_hint+="󰌓 ▏󰖳 + CTRL + 󰯲           Center Window\n"

 keybinds_hint+="━━━━━━━━━━━━━━━━━━ Tmux ━━━━━━━━━━━━━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏CTRL + 󰯬               Tmux: Main Prefix\n"
keybinds_hint+="󰌓 ▏Prefix + Alt + 󰰨       Tmux: List Keymaps\n"
keybinds_hint+="󰌓 ▏Prefix + ?             Tmux: List Keymaps\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰟         Tmux: Reload\n"
keybinds_hint+="󰌓 ▏Prefix + [ OR 󰌑        Tmux: Enter Vim-Mode\n"
keybinds_hint+="󰌓 ▏Prefix + ]             Tmux: Paste Last Yanked\n"
keybinds_hint+="󰌓 ▏Prefix + =             Tmux: Show older yanked text\n"
keybinds_hint+="󰌓 ▏Prefix + 󱁐             Tmux: Change Layout\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰯲         Tmux: Customize options\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰄         Tmux: Install plugin\n"
keybinds_hint+="󰌓 ▏Prefix + 󰯾             Tmux: Open LazyGit\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━━ Tmux Sessions ━━━━━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰢             Tmux: Choose session\n"
keybinds_hint+="󰌓 ▏Prefix + Hold 󰰢        Tmux: Save session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰓             Tmux: New Session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰯵             Tmux: Detach session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰯵         Tmux: Choose session\n"
keybinds_hint+="󰌓 ▏Prefix + $             Tmux: Rename Session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰟             Tmux: Restore session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰍             Tmux: GoTo Last session\n"
keybinds_hint+="󰌓 ▏Prefix + )             Tmux: Move to next session\n"
keybinds_hint+="󰌓 ▏Prefix + (             Tmux: Move to prev session\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰥             Tmux: Show a clock\n"
keybinds_hint+="󰌓 ▏Prefix + ~             Tmux: Show messages\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━━ Tmux Windows ━━━━━━━━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰄             Tmux: Window Info\n"
keybinds_hint+="󰌓 ▏Prefix + 󰯻             Tmux: Find window/pane\n"
keybinds_hint+="󰌓 ▏Prefix + &             Tmux: Kill window\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰮             Tmux: List windows\n"
keybinds_hint+="󰌓 ▏Prefix + 󰯲             Tmux: Create window\n"
keybinds_hint+="󰌓 ▏Prefix + ;             Tmux: Split Window Vertically\n"
keybinds_hint+="󰌓 ▏Prefix + ,             Tmux: Split Window Horizontally\n"
keybinds_hint+="󰌓 ▏Prefix + !             Tmux: Create new window of pane\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━ Tmux Windows Navigating ━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + .         Tmux: Navigate to Next Window\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + ,         Tmux: Navigate to Prev Window\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━ Tmux Panes ━━━━━━━━━━━━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰜             Tmux: Display pane numbers\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰐         Tmux: Clear Marked pane\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰱             Tmux: Kill pane\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━ Tmux Panes Resize ━━━━━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰇         Tmux: Resize DOWN\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰊         Tmux: Resize UP\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰍         Tmux: Resize RIGHT\n"
keybinds_hint+="󰌓 ▏Prefix + 󰘶 + 󰰁         Tmux: Resize LEFT\n"
keybinds_hint+="󰌓 ▏Prefix + 󰰐             Tmux: Maximize/Minimize Pane\n"
keybinds_hint+="━━━━━━━━━━━━━━━━━ Tmux Panes Navigating ━━━━━━━━━━━\n"
keybinds_hint+="󰌓 ▏CTRL + 󰰇               Tmux: Navigate DOWN\n"
keybinds_hint+="󰌓 ▏CTRL + 󰰊               Tmux: Navigate UP\n"
keybinds_hint+="󰌓 ▏CTRL + 󰰍               Tmux: Navigate RIGHT\n"
keybinds_hint+="󰌓 ▏CTRL + 󰰁               Tmux: Navigate LEFT\n"
keybinds_hint+="󰌓 ▏Prefix + >             Tmux: Swap pane RIGHT\n"
keybinds_hint+="󰌓 ▏Prefix + <             Tmux: Swap pane LEFT"

  # Add additional case entries for static sections if necessary
  case_entries+="\"Utils\")\n  $SCRIPTS/utility_script.sh\n  ;;\n"
  case_entries+="\"Windows\")\n  $SCRIPTS/window_control.sh\n  ;;\n"
  case_entries+="\"Workspaces\")\n  $SCRIPTS/workspace_control.sh\n  ;;\n"

  echo -e "$keybinds_hint" > /tmp/keybinds_hint.txt
  echo -e "$case_entries" > /tmp/case_entries.txt
}

# Generate menu content and case entries
parse_keybinds
keybinds_hint=$(cat /tmp/keybinds_hint.txt)
case_entries=$(cat /tmp/case_entries.txt)

# Show Rofi menu
selected=$(echo -e "$keybinds_hint" | rofi -dmenu -p -i -config "$ROFI_CONFIG" | sed 's/.*\s*//')

# Handle selected action
case "$selected" in
$(echo -e "$case_entries")
*)
  echo "No action defined for $selected"
  ;;
esac



"Toggle Split")
  hyprctl dispatch togglesplit
  ;;
"Toggle Floating")
  hyprctl dispatch togglefloating
  ;;
"Toggle Group")
  hyprctl dispatch togglegroup
  ;;


