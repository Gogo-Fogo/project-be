#!/bin/bash
# Run ONCE from the admin account (asks for the admin password):
#   sudo bash /Users/Shared/Emergency/battery-settings.sh
# Battery-only (-b) settings; nothing changes while plugged in. Affects every account.
# Low Power Mode and screen sleep were already set on this Mac (Nov 2026).
# Undo: sudo pmset -b gpuswitch 2
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }

pmset -b lowpowermode 1   # keep: slower CPU bursts, much less drain
pmset -b gpuswitch 0      # integrated GPU only; the Radeon is never used by the AI anyway

echo "Battery settings now:"
pmset -g custom | sed -n '/Battery Power/,/AC Power/p' | grep -E "lowpowermode|gpuswitch|displaysleep"
