# The offline library

[Kiwix](https://kiwix.org) serves `.zim` files: whole websites packed for offline use. The kit
loads every `.zim` in the library folder. The AI searches them, and the browser can open them
directly.

## Books

| File | Size | What it is |
|---|---|---|
| `zimgit-medicine_en` | 0.07 GB | Survival medicine guides (browse only: not searchable) |
| `wikivoyage_en_all_nopic` | 0.3 GB | Travel guide: places, routes, local info |
| `zimgit-post-disaster_en` | 0.6 GB | Post-disaster guides: water, shelter, sanitation (browse only) |
| `mdwiki_en_all_maxi` (WikiMed) | 2.3 GB | Medical encyclopedia, with pictures |
| `ifixit_en_all` | 3.6 GB | Repair guides for phones, laptops, appliances, cars |
| `wikipedia_en_all_mini` | 14 GB | Wikipedia, intro of every article |
| `wikipedia_en_all_nopic` | 53 GB | Full Wikipedia text, no pictures |
| `wikipedia_en_all_maxi` | 127 GB | Full Wikipedia with pictures |

## Tiers

| Tier | Wikipedia edition | Total | Good for |
|---|---|---|---|
| `small` | mini | ~21 GB | Laptops with little space, phones |
| `medium` | no pictures | ~60 GB | Most computers |
| `large` | with pictures | ~134 GB | A desktop or external drive with room |

The Start scripts load only the biggest Wikipedia edition present, so having two editions
doesn't confuse the search.

## Tips

- **Phones:** the Kiwix app (iOS / Android) can download WikiMed and Wikipedia mini directly.
  Good for a phone-only household or as a backup.
- **External drive:** format it exFAT and it works on both Windows and Mac. Plug it into each
  machine to copy the library instead of downloading twice.
- **Searching in the browser:** the front page's search only matches book *names*. Open a book
  first, then search inside it.
- **Verify:** `python3 common/verify-library.py <library folder>` compares every file with
  Kiwix's published SHA-256.
- **New editions:** Kiwix publishes dated editions and removes old ones. If a download 404s, find
  the current file name at https://download.kiwix.org/zim/ and update the script.
- **Mirrors:** download.kiwix.org can be very slow. The scripts try official mirrors first
  (ftp.fau.de, mirror.accum.se), which ran at 14–16 MB/s in testing.
- **Other languages:** every book above exists in many languages. Swap `_en_` for the language
  code.
