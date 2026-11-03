#!/usr/bin/env python3
"""Run a fixed question set through ask.py: library search alone, then each named model.
Kiwix and Ollama must already be running (Start-Emergency / Start Emergency.command).

    python quality_test.py --search-only                 # keyword search only, no AI
    python quality_test.py qwen3.5:4b gemma4:12b         # full answers, one model at a time

Models must be named (never "all installed": the big ones can freeze the PC).
"""
import subprocess
import sys
import time
from pathlib import Path

ASK = Path(__file__).with_name("ask.py")

QUESTIONS = [
    "How do I make water safe to drink?",                        # survival
    "What are the signs of hypothermia and what should I do?",   # medical
    "Someone is bleeding badly from the leg, what do I do?",     # medical, life-threatening -> 911 first
    "How do I do CPR on an adult?",                              # medical, life-threatening
    "What are the symptoms of carbon monoxide poisoning?",       # power-outage hazard (generators, grills)
    "The power is out, how long is food in the fridge safe?",    # everyday wording
    "How do I replace a MacBook Pro battery?",                   # iFixit
    "What was the score of yesterday's Lakers game?",            # NOT in the library -> must refuse
]


def run(args, timeout=300):
    t = time.time()
    try:
        out = subprocess.run([sys.executable, str(ASK), *args], capture_output=True, text=True,
                             encoding="utf-8", errors="replace", timeout=timeout).stdout
    except subprocess.TimeoutExpired:
        out = "(TIMED OUT)"
    return out.strip(), time.time() - t


def main():
    models = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--search-only" in sys.argv:
        for q in QUESTIONS:
            for mode in (["--no-topics"], ["--model", "gemma4:12b"]):
                out, secs = run(["--search-only", *mode, q])
                label = "keywords only" if mode == ["--no-topics"] else "keywords + AI topics"
                print(f"=== {q}  [{label}, {secs:.1f} s]\n{out}\n", flush=True)
        return
    if not models:
        sys.exit("Name the models to test, or pass --search-only.")
    for m in models:
        for q in QUESTIONS:
            out, secs = run(["--model", m, q])
            print(f"=== [{m}] {q}  ({secs:.1f} s)\n{out}\n", flush=True)


if __name__ == "__main__":
    main()
