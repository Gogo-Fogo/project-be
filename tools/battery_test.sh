#!/bin/bash
# Battery cost of ask.py on the MacBook: idle baseline, then the same questions per model.
# Run unplugged. Reports mAh used, average watts, and seconds per answer.
E=~/Emergency
QUESTIONS=(
  "how to treat a second degree burn"
  "signs of hypothermia and what to do"
  "how to purify drinking water without power"
  "signs of dehydration in children"
  "how to stop heavy bleeding from a cut"
)

mah()   { ioreg -rn AppleSmartBattery | awk -F' = ' '$1 ~ /^ *"AppleRawCurrentCapacity"$/ {print $2; exit}'; }
volts() { ioreg -rn AppleSmartBattery | awk -F' = ' '$1 ~ /^ *"Voltage"$/ {print $2 / 1000; exit}'; }

# The capacity gauge updates in jumps, so power is measured by sampling instantaneous current every 2 s instead.
# InstantAmperage is a signed 64-bit value printed unsigned; bc does the wrap exactly (awk doubles can't).
watts() {
  local raw v
  raw=$(ioreg -rn AppleSmartBattery | awk -F' = ' '$1 ~ /^ *"InstantAmperage"$/ {print $2; exit}')
  v=$(ioreg -rn AppleSmartBattery | awk -F' = ' '$1 ~ /^ *"Voltage"$/ {print $2; exit}')
  echo "a=$raw; if (a > 2^63) a -= 2^64; scale=2; -a * $v / 1000000" | bc
}

sample() { : > /tmp/watts.txt; while true; do watts >> /tmp/watts.txt; sleep 2; done; }

report() { # $1 label, $2 seconds, $3 answers
  awk -v l="$1" -v s="$2" -v n="$3" '{ sum += $1; c++ } END {
    w = sum / c; wh = w * s / 3600
    printf "%-22s avg %5.1f W over %4d s", l, w, s
    if (n > 0) printf "  %4.0f s/answer  %5.2f Wh/answer (%4.1f%% of a full battery)", s / n, wh / n, wh / n / 83.4 * 100
    printf "\n" }' /tmp/watts.txt
}

phase() { # $1 label, $2 answers, rest = command
  local label=$1 n=$2 t; shift 2
  sample & local sp=$!; t=$(date +%s)
  "$@"
  kill $sp 2>/dev/null; wait $sp 2>/dev/null
  report "$label" $(( $(date +%s) - t )) $n
}

ask_all() { for q in "${QUESTIONS[@]}"; do /usr/bin/python3 $E/ask.py --model "$1" "$q" >/dev/null; done; }

pgrep -f Emergency/ollama >/dev/null || (OLLAMA_MODELS=$E/models OLLAMA_MAX_LOADED_MODELS=1 nohup $E/ollama/ollama serve >$E/logs/ollama.log 2>&1 &)
pgrep -f kiwix-serve >/dev/null || (nohup $E/kiwix/kiwix-serve --address=127.0.0.1 --port=8080 $E/library/*.zim >$E/logs/kiwix.log 2>&1 &)
sleep 5

echo "start: $(pmset -g batt | grep -o '[0-9]*%')  $(mah) mAh"
phase "idle (services up)" 0 sleep 60
for model in qwen3.5:4b qwen3.5:2b-q4_K_M; do
  phase "$model" ${#QUESTIONS[@]} ask_all "$model"
done
echo "end:   $(pmset -g batt | grep -o '[0-9]*%')  $(mah) mAh"
bash "$E/Stop Emergency.command" >/dev/null
