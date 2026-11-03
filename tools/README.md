# tools/: the programs

Python 3.9+, standard library only (no pip installs), so they run on the Mac's built-in Python
with no internet. Windows runs them from this folder; `mac/install.sh` copies them into the
shared folder on macOS/Linux.

## How a question is answered

```
question ──► ask.py ──► cards/*.txt           (KEYWORDS match → card shown first, verbatim)
                │
                ├──► Ollama: pick search topics   (skipped with --no-topics)
                ├──► kiwix-serve :8080: search the books, exact titles first
                ├──► read the best articles, keep the most relevant paragraphs
                └──► Ollama: answer from those sources only, temperature 0
                         │
chat_server.py :8090 ◄───┘  (streams ask.py's printed output to the browser)
```

Rules built into the prompt:
- use only the sources
- keep adult/child/baby steps apart
- no hospital-only steps
- say when the library has no answer

A "call 911" line is added by code, not by the model, when the question or the top article is
about a life-threatening emergency. The number comes from the `EMERGENCY_NUMBER` environment
variable, default 911.

## Files

| File | Use |
|---|---|
| `ask.py` | The question tool. Interactive: `python ask.py`. One question: `python ask.py how do I treat a burn`. Options: `--model`, `--sources N` (articles to read, default 3), `--chars N` (per article, default 2500), `--think`, `--search-only`, `--no-topics`, `--kiwix URL`, `--ollama URL`. |
| `chat_server.py` | The family chat page. `python chat_server.py --model gemma4:12b` → http://127.0.0.1:8090. Offers only the safe models (see `FAMILY_MODELS`). Started by the Start launchers. |
| `quality_test.py` | `python quality_test.py qwen3.5:4b gemma4:12b`: the same question set through each model, one at a time. `--search-only` tests the library search with no AI. |
| `bench.py` | `python bench.py qwen3.5:4b qwen3.5:2b-q4_K_M`: times each model on the same prompt. **Always pass a model list**: with none it loads every installed model, including big ones. |
| `battery_test.sh` | Mac, unplugged: battery cost per answer, per model. |

## Before changing `ask.py`

- `chat_server.py` parses its printed output. Keep these lines exactly as they are:
  - `Looking up: `
  - `  [n] Title  (book)  url`
  - `Answer (`
  - the 911 line
  - the dashed separator before "From the library"
- Test with a small model (2b/4b) as well as a big one: small models copy prompt examples if
  they're given the chance.
- On macOS/Linux, re-run `bash mac/install.sh --no-library --no-models` to copy the changed
  files into the shared folder.
