EMERGENCY LIBRARY + AI  —  Mac / laptop
=======================================

Everything here works with NO internet. It lives in one shared folder (on a Mac:
/Users/Shared/Emergency), so every account on this computer can use it. The shortcuts
are on the Desktop after running setup-account.sh once in that account.

START
  Double-click "Start Emergency".
    - The "Emergency Help" page opens in the browser. Type a question (or tap an example)
      and press Ask. The AI answers only from the offline library and lists the articles
      it used as [1], [2], [3]; click them to read the full article.
    - "Open library" (top right) opens the whole library (Wikipedia, WikiMed medical
      encyclopedia, survival guides, iFixit repair guides, Wikivoyage).
    - On a laptop without a strong graphics card an answer takes about 1 minute.
      "Stop" stops an answer that's taking too long.
    - The menu at the top picks the AI. The smallest one is fastest and uses the least battery.

QUICK-REFERENCE CARDS (fastest, no AI)
  The "Emergency Cards" folder on the Desktop has short, checked steps for: choking, CPR,
  severe bleeding, burns, heart attack/stroke, food in a power outage, safe water, carbon
  monoxide. Asking about one of these shows the card instantly, before the AI answers.
  PRINT them and keep the paper with the emergency kit.
  To print: open "Print Emergency Cards.html" in that folder and press Print.

FIRST-AID VIDEOS (if they were downloaded)
  "Emergency Videos" on the Desktop: short official videos (Red Cross, American Heart
  Association, St John Ambulance, FEMA) on CPR, choking, bleeding, burns, stroke, seizures,
  allergies, cold injuries, fire safety and more. Watch them NOW, not for the first time in
  an emergency.

SEARCHING THE LIBRARY IN THE BROWSER
  The search box on the library's front page only searches book NAMES. To search articles,
  click a book first (e.g. "WikiMed" for medical), then use the search bar at the top.
  The two survival-guide books (Medicine, Post-Disaster) can't be searched: open them and
  browse the list of guides. Short searches work best: "burn", "water purification".

LOW BATTERY
  Double-click "Ask (low battery)" instead: a smaller AI, about twice as fast, less careful.
  Or skip the AI and just search the library.

STOP
  Double-click "Stop Emergency" when finished. The AI uses a lot of battery while answering.

IMPORTANT
  - The AI can be wrong. For medical questions, read the WikiMed article it cites.
  - Call your emergency number if you can.

BATTERY (measured on a 2019 Intel MacBook Pro): about 13 hours with the kit just running;
  each AI answer uses about 0.5% with the default model, 0.2% with the low-battery one.

FOLDERS
  ollama/   the AI program        models/   AI models
  kiwix/    the library program   library/  library files (.zim)
  docs/     checklists and plans  logs/     logs
