# cards/: quick-reference cards

Short, checked instructions for emergencies where a wrong step is dangerous. They work with
no AI and no power once printed. `README.txt` is the family-facing list; this file is for
maintaining the cards.

## The cards

| Card | Covers |
|---|---|
| `choking.txt` | Adult, child and baby choking |
| `cpr.txt` | CPR for adults, children and babies, and using an AED |
| `bleeding.txt` | Severe bleeding, tourniquets |
| `burns.txt` | Burns and scalds |
| `heart-attack-stroke.txt` | Warning signs, BE FAST |
| `power-outage-food.txt` | Fridge and freezer food safety in an outage |
| `safe-water.txt` | Boiling, and bleach doses for drinking water |
| `carbon-monoxide.txt` | Generators, grills, CO symptoms |

Written Nov 2026 from US public guidance: American Red Cross, American Heart Association, USDA,
CDC, EPA. The cards say **911**. Outside the US, copy them to `my-cards/`, change the number and
print those (AGENTS.md, Phase 4).

**Print:** open `Print Emergency Cards.html` in a browser and print. Cards are never split across pages.

## How the question tool uses them

The first line of each card is `KEYWORDS: word, word, ...`. `tools/ask.py` matches these
(whole words) against the question, shows up to 2 matching cards **first and word for word**,
then the AI answer. It tells the AI the card wins if the two disagree.

## Adding or changing a card

1. Plain text, short lines, numbered steps. First line `KEYWORDS: ...`.
2. Use only official sources (Red Cross, AHA, CDC, USDA, EPA, FEMA).
3. Add the card to `Print Emergency Cards.html` and to `README.txt`.
4. On macOS/Linux, re-run `bash mac/install.sh --no-library --no-models` to copy the cards
   into the shared folder.
5. Reprint.
