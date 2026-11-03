# Offline games

For long days without power or internet. All are free, open source, official releases, and work
offline once installed. 🔋 = barely uses battery, 🔋🔋 = a little, 🔌 = play plugged in.

| Game | Like | Players | Controllers | Battery | Windows | Mac |
|---|---|---|---|---|---|---|
| Battle for Wesnoth | Turn-based fantasy strategy | 1–8, hot-seat | — | 🔋 | ✅ | ✅ |
| Hedgewars | Worms | 1–8, hot-seat | — | 🔋 | ✅ | ✅ |
| OpenTTD | Transport Tycoon | 1 (+LAN) | — | 🔋 | ✅ | ✅ |
| Dungeon Crawl Stone Soup | Roguelike dungeon crawler | 1 | — | 🔋 | ✅ | ✅ |
| Heroes 2 (fheroes2 + free demo) | Heroes of Might and Magic II | 1–6, hot-seat | — | 🔋 | ✅ | — |
| OpenRA | Red Alert, Command & Conquer, Dune 2000 | 1 + bots (+LAN) | — | 🔋🔋 | ✅ | ✅ |
| Blobby Volley 2 | 1v1 volleyball | 2 local | ✅ | 🔋🔋 | ✅ | ✅ |
| Pixel Wheels | Retro top-down racing | 1–4 local | ✅ | 🔋🔋 | ✅ | ✅ |
| SuperTux | Mario-style platformer | 1 | ✅ | 🔋🔋 | ✅ | ✅ |
| Armagetron Advanced | Tron light-cycles | up to 4, split-screen | ✅ | 🔋🔋 | ✅ | ✅ |
| SuperTuxKart | Kart racing | 1–4, split-screen | ✅ | 🔌 | ✅ | — |
| 0 A.D. | Age of Empires | 1 + bots (+LAN) | — | 🔌 | ✅ | ✅ |

**Install:**
- Windows: `windows/get-games-pc.ps1`, then `get-games-pc-2.ps1`.
- macOS: `mac/get-games-mac.sh`, then `get-games-mac-2.sh`, from an admin account.
- **OpenRA** needs its free game files: run `python common/get-openra-content.py` while still
  online.
- **Heroes 2** downloads the free official demo with its own checksum-checked script. For the
  full game, buy *Heroes of Might and Magic II* or *III* on GOG (DRM-free, works offline).

**Not included:** there is no good free, legal fighting game like Tekken or Street Fighter. A
paid one is up to you. GOG sells DRM-free games that work fully offline, and so does Steam once a
game is installed and Steam is set to offline mode.

**Notes:**
- On macOS, the SuperTux disk image shows a license agreement, which can stop the script.
  Open the `.dmg` from `games-downloads/` by hand and drag the app to Applications.
- Hedgewars with Worms-style teams on one machine: everyone shares the keyboard, taking turns.
