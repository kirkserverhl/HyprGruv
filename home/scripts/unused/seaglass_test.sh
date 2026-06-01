#!/bin/bash
# SeaGlass Styling Script for Arch Hyprland with KDE

# Check hyprpm
if ! command -v hyprpm &> /dev/null; then
  echo "hyprpm not found. Install Hyprland plugins manager."
  exit 1
fi

# Automate parts
# Symlink userContent.css
touch ~/.cache/wal/userContent.css
ln -sf ~/.cache/wal/userContent.css ~/.mozilla/firefox/default/chrome/userContent.css

# Write userChrome.css
mkdir -p ~/.mozilla/firefox/default/chrome
cat << CSS > ~/.mozilla/firefox/default/chrome/userChrome.css
@import url('blurredfox/userChrome.css');
@import url('userContent.css');
@import url('layout.css');
CSS

# Append to hyprland.conf if not present
HYPR_CONF=~/.config/hypr/hyprland.conf
grep -q "exec-once = kded5" $HYPR_CONF || echo "exec-once = kded5" >> $HYPR_CONF
grep -q "exec-once = /usr/lib/org_kde_powerdevil" $HYPR_CONF || echo "exec-once = /usr/lib/org_kde_powerdevil" >> $HYPR_CONF

# Install pyprland
yay -S --noconfirm pyprland || echo "pyprland install failed."

# Remove conflicting package and install
yay -Rns --noconfirm python-pywal16 || echo "Removal failed."
yay -S --noconfirm kde-material-you-colors wpgtk lightly-qt python-haishoku python-pywal bibata-cursor-theme || echo "Install failed."

# Enable service
sudo systemctl enable --now power-profiles-daemon || echo "Service enable failed."

# Symlink seaglass-theme.sh to PATH
mkdir -p ~/bin
ln -sf ~/.hyprgruv/lib/scripts/seaglass-theme.sh ~/bin/seaglass-theme

# Symlink KDE theme if folder exists in repo (assume path; adjust if needed)
mkdir -p ~/.local/share/plasma/look-and-feel
ln -sf ~/.hyprgruv/lib/kde-theme ~/.local/share/plasma/look-and-feel/seaglass || echo "KDE theme symlink failed; check path."

# Symlink index.js
mkdir -p /opt/darkreader-pywal
ln -sf ~/.hyprgruv/home/opt/index.js /opt/darkreader-pywal/index.js

# Load pywal colors if available, else default dark
if [ -f ~/.cache/wal/colors.sh ]; then
  . ~/.cache/wal/colors.sh
else
  background="#121212"
  foreground="#ffffff"
  color1="#bbccdd"
  color2="#88aabb"
fi

# Generate HTML guide with dark mode
cat << EOF > seaglass_guide.html
<!DOCTYPE html>
<html>
<head>
<title>SeaGlass Setup Guide</title>
<style>
body {
  background-color: $background;
  color: $foreground;
  font-family: sans-serif;
}
h1, h2 {
  color: $color1;
}
a {
  color: $color2;
}
</style>
</head>
<body>
<h1>SeaGlass Styling for Arch Hyprland</h1>
<p>Use Firefox unless unavailable. Follow checklist below. Files from git repo noted with 📦. Automated parts done.</p>

<h2>Firefox Pywal Customization</h2>
<ul>
<li><input type="checkbox"> In Firefox, navigate to <a href="about:config">about:config</a> and set toolkit.legacyUserProfileCustomizations.stylesheets to true.</li>
<li><input type="checkbox"> Install pywalfox extension: <a href="https://addons.mozilla.org/en-US/firefox/addon/pywalfox/">Install from Mozilla Add-ons</a> or see <a href="https://github.com/frewacom/Pywalfox">GitHub setup</a></li>
<li><input type="checkbox"> Install modified Darkreader: <a href="https://github.com/alexhulbert/SeaGlass/raw/main/user/files/darkreader.xpi">darkreader.xpi</a></li>
<li><input type="checkbox"> In Darkreader: Enable Preview new design, Synchronize site fixes.</li>
</ul>

<h2>Chrome Pywal Customization</h2>
<ul>
<li><input type="checkbox"> Similar steps; adapt for Chrome.</li>
<li><input type="checkbox"> NativeMessagingHosts/darkreader.json.</li>
<li><input type="checkbox"> Load unpacked extension from zip: <a href="https://github.com/alexhulbert/SeaGlass/raw/main/user/files/darkreader-chrome.zip">darkreader-chrome.zip</a></li>
</ul>

<h2>Theming Applications</h2>
<ul>
<li><input type="checkbox"> Run seaglass-theme on DE load (add to hyprland.conf exec-once if needed).</li>
</ul>

<button onclick="window.close()">Finish Styling & Close</button>
</body>
</html>
EOF

# Open in browser
if command -v firefox &> /dev/null; then
  firefox seaglass_guide.html
else
  xdg-open seaglass_guide.html
fi

# Run wal after
wal -R || echo "wal -R failed."
