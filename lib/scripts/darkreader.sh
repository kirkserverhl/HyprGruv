#!/bin/bash

echo "First Open firefox and navigate to about:config in the URL bar."

gum spin --title "Set toolkit.legacyUserProfileCustomizations.stylesheets to true"

echo "Are you ready for step 2?"

gum confirm && rm file.txt || echo "you slow"

gum confirm && rm file.txt || '~/.hyprgruv/assets/scripts/firefox.sh'

echo "Next Install the Transparency Firefox theme by Double clicking to open the 'darkreader.xpi' file:"

dolphin ~/.mozilla/firefox/default/chrome >/dev/null 2>&1

gum spin --title "Openinng Darkreader location... " -- sleep 5

echo "    Open the dark reader extension again, click Settings, go to the Advanced tab, and enable Synchronize site fixes

Close and reopen firefox and the theme should be applied."

echo "The final step to configure firefox is to "
