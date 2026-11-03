# Hardware and AI models

The AI runs on [Ollama](https://ollama.com). It answers only from the offline library, so a small
model that follows the rules beats a big one that improvises.

## Pick a model by machine

| Machine | Default model | Low-battery / fallback | Answer time |
|---|---|---|---|
| Old or small laptop, 8 GB RAM, no GPU | `qwen3.5:2b-q4_K_M` (1.9 GB) | the same | ~25 s on an Intel i9 |
| Laptop, 16 GB RAM, no GPU (e.g. Intel Mac) | `qwen3.5:4b` (3.3 GB) | `qwen3.5:2b-q4_K_M` | ~50 s (measured, 2019 MacBook Pro i9) |
| Apple Silicon Mac, 16 GB+ | `qwen3.5:4b` or `qwen3.5:9b` (6.6 GB) | `qwen3.5:2b-q4_K_M` | not measured: run `tools/bench.py` |
| NVIDIA GPU, 8 GB VRAM | `qwen3.5:4b` | `qwen3.5:2b-q4_K_M` | seconds |
| NVIDIA GPU, 12–16 GB VRAM | `gemma4:12b` (8 GB) | `qwen3.5:4b` | ~7–12 s (measured, RTX 5070 Ti) |

**Rule:** the model's size must be at most **GPU memory − 2 GB**. On a CPU, it must be at most
**half the RAM**. On a laptop, prefer the smaller model: it uses about half the battery per answer.

## Tested and not recommended for family use

| Model | Problem found in testing |
|---|---|
| `gpt-oss:20b` | Invents facts even with sources (e.g. "fridge food safe 1–7 days"; the real guidance is ~4 h). |
| Any "abliterated" / "uncensored" model | Adds unsourced advice (e.g. "call 911" for a broken laptop, wrong medical steps). |
| Models over ~13 GB on a 16 GB GPU | They spill into system RAM. One froze Windows (no VRAM left for the screen). Use them only with the owner present, one at a time. |

## Measured numbers (Nov 2026)

**Desktop: RTX 5070 Ti 16 GB, 64 GB RAM**

| Model | Writes | Real answer |
|---|---|---|
| `qwen3.5:2b-q4_K_M` | 269 tok/s | ~9 s |
| `qwen3.5:4b` | 166 tok/s | ~9 s |
| `qwen3.5:9b` | 111 tok/s | ~12 s |
| `gemma4:12b` | 131 tok/s | ~7–12 s |

`gemma4:12b` was the most faithful of all: it cited everything and never invented anything.

**Laptop: 2019 MacBook Pro 16", Intel i9, CPU only, 83 Wh battery**

| Model | Writes | Real answer | Battery per answer |
|---|---|---|---|
| `qwen3.5:2b-q4_K_M` | 18.7 tok/s | ~25 s | 0.2% (0.20 Wh) |
| `qwen3.5:4b` | 9.2 tok/s | ~50 s | 0.5% (0.42 Wh) |
| `qwen3.5:9b` | 5.3 tok/s | ~2 min | n/a |

Idle with the library + AI running: 6.2 W, about **13 hours** on a full battery. The screen
matters more than the AI.

Measure your own: `python tools/bench.py qwen3.5:4b qwen3.5:2b-q4_K_M` (always pass a model
list), and on a Mac, unplugged: `bash tools/battery_test.sh`.

## Safety settings (already in the Start scripts)

| Variable | Value | Why |
|---|---|---|
| `OLLAMA_GPU_OVERHEAD` | 2 GB | Leaves graphics memory for the screen. |
| `OLLAMA_MAX_LOADED_MODELS` | 1 | Never two models in memory at once. |
| `OLLAMA_LOAD_TIMEOUT` | 2m | Gives up on a stuck load instead of hanging. |
| `OLLAMA_KEEP_ALIVE` (Mac) | 5m | Unloads the model when idle, to save battery. |

Optional extra guard on NVIDIA: Control Panel → Manage 3D settings → *CUDA – Sysmem Fallback
Policy* → *Prefer No Sysmem Fallback*.

## Power

A desktop with a big GPU can draw 300–600 W: a small power station (about 250 Wh) runs it for
well under an hour. Plan on a laptop for outages. Charge the power station from solar or
off-peak. Power priority in an outage: medical devices → phones and radio → lights → laptop →
desktop.
