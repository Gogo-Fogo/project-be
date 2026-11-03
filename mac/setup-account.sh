#!/bin/bash
# Run ONCE while logged in to the "Emergency" account (Terminal, no password needed):
#   bash /Users/Shared/Emergency/setup-account.sh
# Puts the shortcuts on the Desktop and turns down visual effects to save battery.
E="${EMERGENCY_HOME:-/Users/Shared/Emergency}"

for f in "Start Emergency.command" "Ask (low battery).command" "Stop Emergency.command" "README.txt"; do
    ln -sf "$E/$f" "$HOME/Desktop/$f"
done
ln -sfn "$E/cards" "$HOME/Desktop/Emergency Cards"
ln -sfn "$E/videos" "$HOME/Desktop/Emergency Videos"
# OpenRA (Red Alert, C&C, Dune 2000): game files are pre-installed in the shared folder
mkdir -p "$HOME/Library/Application Support/OpenRA"
ln -sfn "$E/openra/Content" "$HOME/Library/Application Support/OpenRA/Content"
echo "Shortcuts added to the Desktop."

# Less animation and transparency = less GPU work on battery
defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null
defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null
# No background downloads of Siri/Spotlight suggestions
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true 2>/dev/null
echo "Visual effects reduced (log out and back in if they haven't changed yet)."

open "$E/README.txt"
echo "Done."
