#!/bin/bash
# Installs the kit on macOS (Intel or Apple Silicon) or Linux into one shared folder.
# Resumable: re-running continues downloads and skips finished ones.
#
#   bash mac/install.sh [--home DIR] [--tier small|medium|large] [--model M] [--low-model M]
#                       [--number 911] [--no-library] [--no-models]
#
# Default folder: /Users/Shared/Emergency on macOS (every account can use it), ~/Emergency on Linux.
# Pick tier and models with docs/LIBRARY.md and docs/HARDWARE-AND-MODELS.md first.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OS=$(uname -s); ARCH=$(uname -m)
if [ "$OS" = Darwin ]; then E="${EMERGENCY_HOME:-/Users/Shared/Emergency}"; else E="${EMERGENCY_HOME:-$HOME/Emergency}"; fi
TIER=medium; MODEL=qwen3.5:4b; LOW=qwen3.5:2b-q4_K_M; NUMBER=911; LIB=1; MODELS=1
while [ $# -gt 0 ]; do
    case "$1" in
        --home) E="$2"; shift ;;
        --tier) TIER="$2"; shift ;;
        --model) MODEL="$2"; shift ;;
        --low-model) LOW="$2"; shift ;;
        --number) NUMBER="$2"; shift ;;
        --no-library) LIB=0 ;;
        --no-models) MODELS=0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo "=== Installing into $E ($OS $ARCH, library: $TIER, model: $MODEL)"
mkdir -p "$E"/{library,kiwix,models,logs,cards,docs} || exit 1

# 1. Programs, cards, docs and launchers
cp "$REPO"/tools/ask.py "$REPO"/tools/chat_server.py "$E/"
cp "$REPO"/cards/* "$E/cards/"
cp "$REPO"/docs/*.md "$E/docs/"
cp "$REPO"/mac/*.command "$REPO"/mac/setup-account.sh "$REPO"/mac/battery-settings.sh \
   "$REPO"/mac/get-games-mac*.sh "$REPO"/mac/README.txt "$E/"
chmod +x "$E"/*.command "$E"/*.sh
cat > "$E/emergency.env" <<EOF
# Read by the launchers. A value already set (e.g. by "Ask (low battery)") wins.
EMERGENCY_MODEL="\${EMERGENCY_MODEL:-$MODEL}"
EMERGENCY_LOW_BATTERY_MODEL="$LOW"
EMERGENCY_NUMBER="$NUMBER"
EOF

# 2. kiwix-serve (the library server)
case "$OS-$ARCH" in
    Darwin-arm64)  KT=kiwix-tools_macos-arm64-3.8.1.tar.gz ;;
    Darwin-x86_64) KT=kiwix-tools_macos-x86_64-3.8.1.tar.gz ;;
    Linux-x86_64)  KT=kiwix-tools_linux-x86_64-3.8.1.tar.gz ;;
    Linux-aarch64) KT=kiwix-tools_linux-aarch64-3.8.1.tar.gz ;;
    *) echo "!!! No kiwix-tools build for $OS-$ARCH"; exit 1 ;;
esac
MIRRORS="https://ftp.fau.de/kiwix https://mirror.accum.se/mirror/kiwix.org https://download.kiwix.org"
fetch() {  # kiwix path, output file: tries each mirror, resumes partial files
    for m in $MIRRORS; do
        curl -L -C - --retry 3 --retry-delay 10 -s -S --speed-limit 512000 --speed-time 60 -o "$2" "$m/$1" && return 0
        echo "    mirror $m failed, trying next"
    done
    echo "!!! FAILED: $1"; return 1
}
if [ ! -x "$E/kiwix/kiwix-serve" ]; then
    echo "=== kiwix-tools"
    fetch "release/kiwix-tools/$KT" "$E/kiwix/$KT" && tar xzf "$E/kiwix/$KT" -C "$E/kiwix" --strip-components 1 && rm "$E/kiwix/$KT"
fi

# 3. Ollama (the AI runner): use an installed one, or put the official build in the folder (macOS)
OLL=$(command -v ollama || true)
if [ -z "$OLL" ] && [ ! -x "$E/ollama/ollama" ]; then
    if [ "$OS" = Darwin ]; then
        echo "=== Ollama"
        mkdir -p "$E/ollama"
        curl -L --retry 3 -s -S -o "$E/ollama/ollama-darwin.tgz" https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.tgz &&
            tar xzf "$E/ollama/ollama-darwin.tgz" -C "$E/ollama" && rm "$E/ollama/ollama-darwin.tgz"
    else
        echo "!!! Install Ollama first (official instructions: https://ollama.com/download/linux), then re-run."
        exit 1
    fi
fi
[ -x "$E/ollama/ollama" ] && OLL="$E/ollama/ollama"

# 4. Library (see docs/LIBRARY.md). If a file 404s, Kiwix has a newer edition: update the name.
if [ "$LIB" = 1 ]; then
    case "$TIER" in
        small)  WP=zim/wikipedia/wikipedia_en_all_mini_2026-09.zim ;;
        medium) WP=zim/wikipedia/wikipedia_en_all_nopic_2026-06.zim ;;
        large)  WP=zim/wikipedia/wikipedia_en_all_maxi_2026-08.zim ;;
        *) echo "Unknown tier $TIER"; exit 1 ;;
    esac
    for z in zim/other/zimgit-medicine_en_2024-08.zim zim/wikivoyage/wikivoyage_en_all_nopic_2026-09.zim \
             zim/other/zimgit-post-disaster_en_2024-05.zim zim/other/mdwiki_en_all_maxi_2025-11.zim \
             zim/ifixit/ifixit_en_all_2025-12.zim "$WP"; do
        echo "=== $(date +%H:%M:%S) $(basename "$z")"
        fetch "$z" "$E/library/$(basename "$z")"
    done
fi

# 5. Models, stored in the shared folder
if [ "$MODELS" = 1 ]; then
    export OLLAMA_MODELS="$E/models"
    started=0
    if ! curl -s -m 2 http://127.0.0.1:11434/api/version >/dev/null; then
        "$OLL" serve >"$E/logs/ollama-install.log" 2>&1 & started=$!
        sleep 5
    fi
    for m in $(printf '%s\n' "$LOW" "$MODEL" | awk '!seen[$0]++'); do
        echo "=== model $m"; "$OLL" pull "$m" || echo "!!! FAILED: $m"
    done
    [ "$started" != 0 ] && kill "$started"
fi

chmod -R a+rX "$E"; chmod a+rwx "$E/logs"
echo "=== Done. Next:"
echo "  - verify the library: python3 \"$REPO/common/verify-library.py\" \"$E/library\""
[ "$OS" = Darwin ] && echo "  - in each account that will use it: bash \"$E/setup-account.sh\""
echo "  - test with Wi-Fi OFF: double-click \"Start Emergency\" and ask a question"
