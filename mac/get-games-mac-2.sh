#!/bin/bash
# More free, open-source games for the Mac (round 2), official releases only.
#   0 A.D.           Age of Empires-style strategy (heavy on battery: play plugged in)
#   OpenRA           Red Alert / Command & Conquer remake, free and legal
#   Blobby Volley 2  1v1 volleyball, two players on one keyboard / two controllers
#   Armagetron       Tron light-cycles, split-screen
# Run ONCE from the admin account in Terminal (no sudo needed), after get-games-mac.sh:
#   bash /Users/Shared/Emergency/get-games-mac-2.sh
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

get "OpenRA"          openra.dmg     "https://github.com/OpenRA/OpenRA/releases/download/release-20250330/OpenRA-release-20250330.dmg"
get "Blobby Volley 2" blobby.dmg     "https://downloads.sourceforge.net/project/blobby/Blobby%20Volley%202%20%28MacOSX%29/1.1.1/blobby2-macosx-1.1.1.dmg"
get "Armagetron"      armagetron.dmg "https://github.com/ArmagetronAd/armagetronad/releases/download/v0.2.9.3.1/armagetronad-0.2.9.3.1.dmg"
get "0 A.D. (1.6 GB)" 0ad.dmg        "https://releases.wildfiregames.com/0ad-0.28.0-macos-x86_64.dmg"

for f in openra.dmg blobby.dmg armagetron.dmg 0ad.dmg; do
    [ -s "$f" ] && install_app "$f"
done
echo "Done. Games are in Applications (Launchpad)."
echo "ONE MORE STEP while online: open each OpenRA game once and click 'Quick Install'."
