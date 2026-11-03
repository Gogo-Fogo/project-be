#!/usr/bin/env python3
"""Time every installed Ollama model on the same prompt (thinking off, 200 tokens), one at a time.

    python3 bench.py model [model ...]
Models must be named: on the PC, loading every installed model (27B/35B included) froze the machine.
"""
import json
import sys
import urllib.request

OLLAMA = "http://127.0.0.1:11434"
PROMPT = ("A family is preparing for a multi-day power outage in an apartment. "
          "List the ten most important things to do, one short sentence each.")


def post(path, body):
    req = urllib.request.Request(OLLAMA + path, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=1800) as r:
        return json.load(r)


def main():
    with urllib.request.urlopen(OLLAMA + "/api/tags") as r:
        installed = sorted(json.load(r)["models"], key=lambda m: m["size"])
    models = sys.argv[1:]
    if not models:
        sys.exit("Name the models to test, e.g.: bench.py qwen3.5:4b gemma4:12b\nInstalled: "
                 + ", ".join(m["name"] for m in installed))
    sizes = {m["name"]: m["size"] for m in installed}

    print(f"{'model':38} {'size GB':>7} {'load s':>7} {'gen tok/s':>9} {'prompt tok/s':>12}")
    for name in models:
        r = post("/api/generate", {"model": name, "prompt": PROMPT, "stream": False, "think": False,
                                   "keep_alive": 0, "options": {"num_predict": 200, "temperature": 0}})
        gen = r["eval_count"] / (r["eval_duration"] / 1e9)
        prompt = r["prompt_eval_count"] / (r["prompt_eval_duration"] / 1e9)
        print(f"{name:38} {sizes.get(name, 0) / 1e9:7.1f} {r['load_duration'] / 1e9:7.1f} {gen:9.1f} {prompt:12.0f}",
              flush=True)


if __name__ == "__main__":
    main()
