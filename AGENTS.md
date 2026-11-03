# AGENTS.md: setup protocol for AI agents

You are an AI agent (Claude Code, Codex, Copilot, Cursor, Gemini CLI, or similar) helping a person
set up this **offline emergency kit** on their own devices. The kit includes:

- an offline library (Wikipedia, WikiMed, iFixit, survival guides) served by Kiwix
- a local AI (Ollama) that answers only from that library
- printable first-aid cards
- official first-aid videos
- offline games
- checklists for supplies, communications and grid alerts

Follow the phases in order. **Ask before anything big, paid, or system-changing.** The person
may not be technical: explain in plain words, one step at a time.

## Rules (apply in every phase)

1. **The person decides.**
   - Ask before any download over 1 GB, anything that needs `sudo`/admin, any change to system
     settings, and any install.
   - Purchases, passwords, sign-ins and account creation are done by the person, never by you.
2. **Official sources only:** Kiwix mirrors, ollama.com / the Ollama GitHub, the projects' own
   release pages, and the official YouTube channels already listed in `common/get-videos.sh`.
   No random uploaders, no cracked games, no "uncensored" models for family use.
3. **Never freeze their computer.**
   - Load one AI model at a time.
   - On a GPU, keep 2 GB of graphics memory free (`OLLAMA_GPU_OVERHEAD`). The default config
     already does this.
   - Never load a model bigger than (GPU memory − 2 GB) unless the person is at the machine and
     agrees.
   - Don't run a big model test at the same time as a big download.
   - Background: a 27B model filled a 16 GB GPU and froze Windows; see docs/HARDWARE-AND-MODELS.md.
4. **Check space first.**
   - Leave at least 15% of the disk free after everything is installed.
   - External exFAT drives work on both Windows and Mac.
5. **Don't change the output format of `tools/ask.py`.** `tools/chat_server.py` parses it.
6. **Medical content:**
   - The cards and the AI's rules ("only from sources, cards win") are what makes the kit safe.
     Don't loosen them.
   - Tell the person the AI can be wrong, and that they should take a real first-aid class.
7. **Their details stay local.** Put their filled-in plans, addresses and numbers in files named
   `my-*.md` or in `emergency.config.json`. Both are git-ignored. Never commit or push them.
8. **Verify, don't assume.**
   - Checksums for the library.
   - A real no-internet test at the end.
   - Report failures plainly.

## Phase 1: Learn about the person and their devices

Detect what you can, then ask about the rest.

| Detect | Windows (PowerShell) | macOS | Linux |
|---|---|---|---|
| OS + version | `Get-ComputerInfo OsName,OsVersion` | `sw_vers` | `cat /etc/os-release` |
| CPU / architecture | `$env:PROCESSOR_ARCHITECTURE` | `uname -m` (arm64 = Apple Silicon) | `uname -m` |
| RAM | `(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB` | `sysctl -n hw.memsize` | `free -g` |
| GPU + VRAM | `nvidia-smi --query-gpu=name,memory.total --format=csv` (NVIDIA) | Apple Silicon: unified memory = RAM | `nvidia-smi` / `lspci` |
| Free disk | `Get-PSDrive -PSProvider FileSystem` | `df -h /` | `df -h` |
| Laptop? battery health | `powercfg /batteryreport` | `system_profiler SPPowerDataType` | `upower -d` |
| Python 3 | `python --version` | `/usr/bin/python3 --version` | `python3 --version` |

Ask the person:

- **Who is it for?** How many people, their ages (babies, elderly) and medical needs.
- **Which devices?**
  - Which computer stays plugged in, and which one works best on battery?
  - Which phones (iPhone or Android, and the model)?
- **Where they live:**
  - Country and region, for their emergency number and grid operator.
  - Apartment or house.
  - Typical risks: storms, heat, cold, earthquakes, wildfire.
- **What do they already have?** Power station, radio, water, first-aid kit.
- **What they want:**
  - The library and AI, cards, videos, games, or the checklists only.
  - Any languages other than English (Kiwix has many).

Summarise back what you found, in one short table, before continuing.

## Phase 2: Recommend a setup

Use these to choose:
- [docs/HARDWARE-AND-MODELS.md](docs/HARDWARE-AND-MODELS.md): which AI model fits which machine.
- [docs/LIBRARY.md](docs/LIBRARY.md): library tiers and sizes.

A typical plan:

- **Plan A, the plugged-in machine** (often a desktop with a GPU): the biggest library tier that
  fits, the best model that fits in VRAM − 2 GB.
- **Plan B, the battery machine** (a laptop): a small or medium library and a 2–4B model.
  Measure the battery with `tools/battery_test.sh` (Mac) if they want numbers.
- **No capable computer?**
  - Kiwix apps exist for iPhone/iPad, Android, Windows, macOS and Linux. Install the app and
    download WikiMed + Wikipedia mini on the phone.
  - Skip the AI.
  - Cards and videos still work.
- **Phones:** the comms setup in docs/COMMS-PLAN.md, with the iPhone or Android steps.

Present it as one table: device → what goes on it → download size → time estimate.
Get a clear yes before Phase 3.

## Phase 3: Install

Clone this repo somewhere permanent (not Downloads). Then:

### Windows
1. **Install prerequisites (ask first):**
   - Python 3: `winget install Python.Python.3.12`, or the python.org installer with "Add to PATH" ticked.
   - Ollama: `winget install Ollama.Ollama`, or the ollama.com installer.
2. **Create the config:** copy `emergency.config.example.json` to `emergency.config.json` and set:
   - `data_dir`: a drive with space, e.g. `D:\Emergency`.
   - `model` and `low_battery_model`.
   - `library_tier`.
   - `emergency_number`.
   - `ollama_models`: a folder on a drive with space, if C: is small.
3. **Download:**
   - Library: `.\windows\get-library.ps1`. This is the long one: run it in the background and
     check on it.
   - Models: `.\windows\pull-models.ps1`.
4. **Verify the library:** `python common\verify-library.py <data_dir>\Kiwix\library`. Every line
   must say `OK`.
5. **Desktop shortcuts** to `windows\Start Emergency.bat`, `windows\Stop Emergency.bat`,
   `cards\` and `windows\README.txt`. Use a `.lnk` via WScript.Shell, and name them
   "Start Emergency", "Stop Emergency", "Emergency Cards" and "README - Emergency".

### macOS (Intel or Apple Silicon) and Linux
1. **Run:** `bash mac/install.sh --tier medium --model qwen3.5:4b --low-model qwen3.5:2b-q4_K_M --number 911`
   - Pick the values in Phase 2.
   - It installs to `/Users/Shared/Emergency` on macOS (every account can use it) or `~/Emergency`
     on Linux.
   - It downloads kiwix-serve, Ollama (macOS), the library and the models.
   - Use `--no-library` / `--no-models` to stage the work.
2. **Verify:** `python3 common/verify-library.py /Users/Shared/Emergency/library`.
3. **macOS, each account that will use it:** `bash /Users/Shared/Emergency/setup-account.sh`
   (Desktop shortcuts). Suggest a separate standard account named "Emergency" with the shortcuts
   on its desktop, so anyone in the family can find it.
4. **macOS, optional battery tuning:** `sudo bash /Users/Shared/Emergency/battery-settings.sh`.
   It needs the admin password, so the person types it.
5. **Linux:**
   - Install Ollama with the official instructions first.
   - If Ollama runs as a system service, its models live in the service's folder: pull the
     models there and skip `--model` pulls, or set `OLLAMA_MODELS` for the service.
   - The `.command` launchers are bash scripts: make `.desktop` launchers that run them.

### Optional extras (each needs a yes)
- **First-aid videos** (about 900 MB, needs yt-dlp + ffmpeg):
  `bash common/get-videos.sh "<data_dir>/Videos"`. On Mac, use `/Users/Shared/Emergency/videos`.
- **Games:**
  - Windows: `.\windows\get-games-pc.ps1`, then `get-games-pc-2.ps1`.
  - macOS: `get-games-mac.sh`, then `get-games-mac-2.sh`.
  - Then run `python common/get-openra-content.py` so OpenRA works offline. On a shared Mac:
    `python3 common/get-openra-content.py /Users/Shared/Emergency/openra`, then `setup-account.sh`
    makes the link.
  - See [docs/GAMES.md](docs/GAMES.md).
- **Other languages:** add that language's Wikipedia/WikiMed `.zim` from download.kiwix.org.
  Set the model to one that speaks it (Qwen and Gemma are multilingual).

## Phase 4: Adapt to where they live

- **Emergency number** in the config, if it's not 911:
  - Windows: `emergency_number` in `emergency.config.json`.
  - Mac/Linux: `--number`, saved in `emergency.env`.
  - The cards also say "911": copy them to `my-cards/` and change the number for printing.
- **Grid alerts:** find their grid operator and its alert app or emails, and their utility's
  outage texts. See [docs/GRID-ALERTS.md](docs/GRID-ALERTS.md).
- **Local alerts:**
  - Their county/city alert sign-up, and the phone's emergency alerts.
  - A NOAA (US) or national weather radio.
- **Climate:** emphasise the heat or the cold section of docs/READY-2-WEEKS.md to match their
  season and region.

## Phase 5: Test with no internet

1. Turn Wi-Fi off / unplug the network cable.
2. Start the kit with the "Start Emergency" shortcut. Ask:
   - "how do I stop severe bleeding" → the bleeding card shows first, then a cited answer.
   - "how do I purify water" → a cited answer.
   - "what is the capital of Atlantis" → "Not found in the offline library".
3. Open a video and a card. Start one game.
4. Stop the kit and turn the network back on.
5. Report what passed, what failed and why.

## Phase 6: Hand over

Walk the person through these, and help fill in what you can:

- [docs/READY-2-WEEKS.md](docs/READY-2-WEEKS.md): supplies, sized for their household.
- [docs/COMMS-PLAN.md](docs/COMMS-PLAN.md): Signal, SMS, satellite, Bitchat or Briar, radios,
  and the paper table. Save their filled-in copy as `my-comms-plan.md`.
- [docs/GRID-ALERTS.md](docs/GRID-ALERTS.md) and [docs/GRID-SECURITY.md](docs/GRID-SECURITY.md).
- **Print** the cards and the comms table.
- **Watch** the videos now.
- **Book** a first-aid/CPR class.

End with a short list of their remaining to-dos (things only they can do: buying, printing,
installing apps on phones, signing up for alerts).

## Keeping it current

- Every 6 months:
  - `git pull`.
  - Re-run the download scripts (they skip finished files).
  - Check for newer library editions on download.kiwix.org.
  - Refresh stored water.
- If a download link 404s, the project published a newer version: look it up on the official
  page, update the script, and tell the repo owner so everyone gets the fix.
