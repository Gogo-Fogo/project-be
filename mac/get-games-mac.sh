#!/bin/bash
# Free, open-source, battery-friendly games for the Mac (Intel), official releases only.
# Run ONCE from the admin account in Terminal (no sudo needed):
#   bash /Users/Shared/Emergency/get-games-mac.sh
# Apps go to /Applications so every account (including "Emergency") can play them.
set -u
DL="${EMERGENCY_HOME:-/Users/Shared/Emergency}/games-downloads"
mkdir -p "$DL"
cd "$DL" || exit 1

get() { echo "=== $1"; curl -L -C - --retry 3 -s -S -o "$2" "$3" || echo "!!! download failed: $1"; }

install_app() {  # file -> copies every .app inside it (zip or dmg) to /Applications
    local f="$1" tmp
    tmp=$(mktemp -d)
    case "$f" in
        *.zip) ditto -x -k "$f" "$tmp" ;;
        *.dmg) hdiutil attach -nobrowse -readonly -mountpoint "$tmp/mnt" "$f" >/dev/null ;;
    esac
    find "$tmp" -maxdepth 3 -name "*.app" -prune | while read -r app; do
        rm -rf "/Applications/$(basename "$app")"
        ditto "$app" "/Applications/$(basename "$app")" && echo "    -> /Applications/$(basename "$app")"
    done
    [ -d "$tmp/mnt" ] && hdiutil detach -quiet "$tmp/mnt"
    rm -rf "$tmp"
}

# Barely uses battery (turn-based)
get "Battle for Wesnoth"  wesnoth.dmg   "https://downloads.sourceforge.net/project/wesnoth/wesnoth-1.18/wesnoth-1.18.8/Wesnoth_1.18.8.dmg"
get "Hedgewars"           hedgewars.dmg "https://www.hedgewars.org/download/releases/Hedgewars-1.0.0.dmg"
get "OpenTTD"             openttd.dmg   "https://cdn.openttd.org/openttd-releases/15.3/openttd-15.3-macos-universal.dmg"
get "OpenTTD graphics"    opengfx.zip   "https://cdn.openttd.org/opengfx-releases/8.0/opengfx-8.0-all.zip"
get "Dungeon Crawl"       crawl.zip     "https://github.com/crawl/crawl/releases/download/0.34.1/dcss-0.34.1-macos-tiles-universal.zip"
# Uses a little battery (light action, controllers)
get "Pixel Wheels"        pixelwheels.zip "https://github.com/agateau/pixelwheels/releases/download/1.0.1/pixelwheels-1.0.1-mac.zip"
get "SuperTux"            supertux.dmg  "https://github.com/SuperTux/supertux/releases/download/v0.7.0/SuperTux-v0.7.0-Darwin-x86_64.dmg"

for f in wesnoth.dmg hedgewars.dmg openttd.dmg crawl.zip pixelwheels.zip supertux.dmg; do
    [ -s "$f" ] && install_app "$f"
done

# OpenTTD needs a graphics set and can't download it offline: give it OpenGFX now
mkdir -p "$HOME/Documents/OpenTTD/baseset"
ditto -x -k opengfx.zip "$HOME/Documents/OpenTTD/baseset" && echo "    -> OpenGFX for $(whoami)"
echo "Done. Games are in Applications (Launchpad)."
