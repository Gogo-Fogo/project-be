#!/bin/bash
# Double-click: starts the offline library + local AI, opens the library in Safari,
# then asks questions in this window. Close with "Stop Emergency".
E="${EMERGENCY_HOME:-/Users/Shared/Emergency}"   # shared by every account on this Mac
cd "$E" || exit 1
[ -f "$E/emergency.env" ] && . "$E/emergency.env"   # EMERGENCY_MODEL, EMERGENCY_NUMBER (written by install.sh)
export EMERGENCY_NUMBER
OLL="$E/ollama/ollama"; [ -x "$OLL" ] || OLL=$(command -v ollama)
KIWIX="$E/kiwix/kiwix-serve"; [ -x "$KIWIX" ] || KIWIX=$(command -v kiwix-serve)

export OLLAMA_MODELS="$E/models"
export OLLAMA_NOPRUNE=1       # models are shared; never delete files another account owns
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=5m   # unload the model after 5 idle minutes to save battery

if ! curl -s -m 2 http://127.0.0.1:11434/api/version >/dev/null; then
    echo "Starting the AI..."
    nohup "$OLL" serve >"$E/logs/ollama.log" 2>&1 &
fi
if ! curl -s -m 2 http://127.0.0.1:8080 >/dev/null; then
    echo "Starting the library..."
    # Every book, minus the smaller Wikipedia editions when a bigger one is present
    has() { for f in "$@"; do [ -e "$f" ] && return 0; done; return 1; }
    zims=()
    for z in "$E"/library/*.zim; do
        case "$(basename "$z")" in
            wikipedia_en_all_mini_*) has "$E"/library/wikipedia_en_all_{nopic,maxi}_*.zim && continue ;;
            wikipedia_en_all_nopic_*) has "$E"/library/wikipedia_en_all_maxi_*.zim && continue ;;
        esac
        zims+=("$z")
    done
    nohup "$KIWIX" --address=127.0.0.1 --port=8080 "${zims[@]}" >"$E/logs/kiwix.log" 2>&1 &
fi

for i in $(seq 1 30); do
    curl -s -m 2 http://127.0.0.1:8080 >/dev/null && curl -s -m 2 http://127.0.0.1:11434/api/version >/dev/null && break
    sleep 1
done

if ! curl -s -m 2 http://127.0.0.1:8090/models >/dev/null; then
    echo "Starting the question page..."
    nohup /usr/bin/python3 "$E/chat_server.py" --model "${EMERGENCY_MODEL:-qwen3.5:4b}" >"$E/logs/chat.log" 2>&1 &
fi
for i in $(seq 1 15); do
    curl -s -m 2 http://127.0.0.1:8090/models >/dev/null && break
    sleep 1
done

open -a Safari http://127.0.0.1:8090
clear
cat <<'EOF'
==============================================================
  EMERGENCY LIBRARY + AI  (works with no internet)
--------------------------------------------------------------
  The "Emergency Help" page is open in Safari:
      http://127.0.0.1:8090
  Type a question there. "Open library" opens the whole library.
  Run "Stop Emergency" when done (saves battery).
  You can close this window.
==============================================================
EOF
