#!/bin/bash

#!/bin/bash

# Define paths
WAL_FILE="$HOME/.cache/wal/colors.css"
STARSHIP_CONFIG="$HOME/.dotfiles/.config/.config/starship.toml"

# Extract colors from pywal's colors.css using sed
colors=()
for i in {0..9}; do
  # Get the color using sed and strip extra spaces
  color=$(sed -n "s/--color$i: \(#[a-fA-F0-9]\+\);/\1/p" "$WAL_FILE")
  colors+=("$color")
done

# Ensure there are exactly 10 colors extracted
if [ ${#colors[@]} -ne 10 ]; then
  echo "Error: Expected 10 colors from pywal, but found ${#colors[@]}"
  exit 1
fi

# Update the starship.toml file with pywal colors
sed -i \
  -e "s/color_fg = .*/color_fg = '${colors[7]}'/" \
  -e "s/color_0 = .*/color0 = '${colors[0]}'/" \
  -e "s/color_2 = .*/color_2 = '${colors[2]}'/" \
  -e "s/color_3 = .*/color_3 = '${colors[3]}'/" \
  -e "s/color_4 = .*/color_4 = '${colors[4]}'/" \
  -e "s/color_5 = .*/color_5 = '${colors[5]}'/" \
  -e "s/color_6= .*/color_6 = '${colors[6]}'/" \
  -e "s/color_8 = .*/color_8 = '${colors[8]}'/" \
  -e "s/color_9 = .*/color_9 = '${colors[9]}'/" \
  -e "s/color_10 = .*/color_10 = '${colors[10]}'/" \
  "$STARSHIP_CONFIG"

echo "Starship configuration updated with pywal colors!"


