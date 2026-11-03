# Project Be: offline emergency kit

A kit made for family and friends: everything a household needs to stay safe, informed and in
touch if the power, internet or phone network goes down for up to two weeks. Free for personal,
non-commercial use (see [License](#license)).

> **Not medical advice.** The cards, videos and AI answers are general first-aid information
> from public sources, collected by non-professionals. They don't replace emergency services,
> a doctor, or a real first-aid/CPR class. **Call your local emergency number first if you can.**
> The local AI can be wrong. Use everything here at your own risk.

## What you get

- **Offline library:** Wikipedia, WikiMed (medical), iFixit (repairs), survival guides,
  Wikivoyage. Works in any browser, with no internet.
- **Local AI:** ask questions in plain words and get answers taken *only* from the library,
  with the sources listed. It says "not found" instead of guessing. Runs on your own computer.
- **First-aid cards:** 8 short, checked cards to print (choking, CPR, bleeding, burns, heart
  attack/stroke, food in an outage, safe water, carbon monoxide). The AI shows the matching
  card first.
- **First-aid videos:** 48 official videos (Red Cross, American Heart Association, St John
  Ambulance, FEMA), about 900 MB.
- **Offline games:** for long days without power or internet. Many work with controllers for
  2+ players.
- **Checklists:** 2-week supplies, family comms plan, grid alerts, home network security.

Works on **Windows**, **macOS** (Intel and Apple Silicon) and **Linux**. Phones get the comms
setup and, optionally, the Kiwix app.

## How to use it: let your AI agent set it up

No account needed. Open your AI coding agent (Claude Code, Codex, Copilot, Cursor, Gemini
CLI...) and say:

> Clone `https://github.com/Gogo-Fogo/project-be` into a permanent folder and follow AGENTS.md
> to set up the emergency kit for me.

The agent will:
1. Check your computer: system, memory, graphics card, free space, battery.
2. Ask about your household and phones.
3. Recommend what fits: library size, AI model, extras.
4. Install it after you say yes.
5. Test it with the internet off.
6. Walk you through the checklists.

It asks before big downloads and system changes. Purchases, passwords and sign-ups stay with you.

**Doing it by hand?** Read [AGENTS.md](AGENTS.md). It's written for agents but it's plain steps.

## In an emergency

| Situation | Use |
|---|---|
| Power is on | The plugged-in computer: double-click **Start Emergency**. A chat page opens in the browser. |
| Power is out | The laptop: **Start Emergency**, or **Ask (low battery)** on a Mac. |
| No device | The **printed cards**. |
| Someone is hurt | Cards first (checked and instant), then the videos and the chat page. Call your emergency number if you can. |

**The AI can be wrong.** For medical questions, read the article it cites, and take a real
first-aid/CPR class.

## What's in the repo

| Path | Contents |
|---|---|
| [AGENTS.md](AGENTS.md) | **The setup protocol** (agents start here). `CLAUDE.md` points to it. |
| [docs/](docs/) | Guides: [hardware and models](docs/HARDWARE-AND-MODELS.md), [library](docs/LIBRARY.md), [2-week supplies](docs/READY-2-WEEKS.md), [comms plan](docs/COMMS-PLAN.md), [grid alerts](docs/GRID-ALERTS.md), [grid security](docs/GRID-SECURITY.md), [games](docs/GAMES.md). |
| [tools/](tools/README.md) | The question tool (`ask.py`) and chat page (`chat_server.py`), plus benchmark and test tools. Python 3, standard library only. |
| [cards/](cards/README.md) | The first-aid cards and their print page. |
| `windows/` | Start/Stop launchers, library and model downloads, games, family instructions (`README.txt`). Settings: `emergency.config.json` (copy the `.example`). |
| `mac/` | `install.sh` (macOS and Linux), launchers, per-account setup, battery settings, games, family instructions (`README.txt`). |
| `common/` | Cross-platform helpers: library checksum check, first-aid video download, OpenRA game files. |

Nothing big is stored in the repo. Libraries, models, videos and games are downloaded from their
official sources on each machine.

## Your private details

Files named `my-*.md` and `emergency.config.json` are git-ignored: your filled-in comms plan,
addresses and settings stay on your computer. **This repo is public: never commit them, and
never open an issue or pull request that contains them.**

## Contributing fixes

Found a broken download link (Kiwix and game releases get renamed) or a better tip? Open an issue
or a pull request.

## License

This repo's own scripts, cards and guides are licensed under
[CC BY-NC 4.0](LICENSE) (Creative Commons Attribution-NonCommercial): free to use, share and
adapt for non-commercial purposes, with credit. **No commercial use.**

The things the kit downloads keep their own licenses:
- Wikipedia and the other Kiwix books: CC BY-SA.
- Ollama and the AI models: per model.
- The games: GPL and similar.
- The videos: they belong to their publishers and are downloaded for personal offline viewing.

None of these are redistributed here.
