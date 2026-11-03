#!/usr/bin/env python3
"""Ask a question, answered by a local AI from the offline Kiwix library.

Searches every book kiwix-serve is serving, pulls the best few articles, and has
Ollama answer ONLY from them, citing each source. Works fully offline.

    python3 ask.py "how do I treat a second degree burn"
    python3 ask.py                      # interactive, asks until you type q
    python3 ask.py --search-only "..."  # no AI: just the best articles (saves battery)

Standard library only (Python 3.9+), so it runs on a stock Mac.
"""
import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser

KIWIX = "http://127.0.0.1:8080"
OLLAMA = "http://127.0.0.1:11434"
DEFAULT_MODEL = "qwen3.5:4b"

# Books searched first win ties: medical and survival content before general encyclopedias.
BOOK_WEIGHT = {
    "mdwiki": 0.30,
    "zimgit-medicine": 0.25,
    "zimgit-post-disaster": 0.25,
    "wikipedia": 0.10,
    "ifixit": 0.05,
    "wikivoyage": 0.0,
}

STOPWORDS = set("""
a an and are as at be but by can do does for from how i if in into is it its me my of on or should so
that the their them then there these they this to was what when where which who why will with you your
we our us please tell about best way get need make much many any some
""".split())

SYSTEM_PROMPT = """You are an offline emergency assistant. The internet may be down.
Answer the question using ONLY the numbered SOURCES below. Cite them like [1] or [2].
Rules:
- Every fact and step must come from the sources. Never add your own tips or general knowledge.
- If a source gives different steps for adults, children or babies, keep them apart as the source does.
- Leave out anything that needs a hospital or special equipment unless the question asks.
- Use what the sources say even if it doesn't match the question exactly (e.g. general fever
  advice for a specific temperature). A repair guide for a similar model or version still counts:
  give its steps and say which model it is for. Only if nothing in them helps, say only:
  "Not found in the offline library."
- Do not tell the reader to call emergency services; the program adds that line itself.
Be practical: short steps, plain words."""

# Small models (2b) get lost in the long rule list and start copying the sources back
SHORT_PROMPT = """Answer the question using ONLY the numbered SOURCES. Cite them like [1].
Short steps, plain words. Don't add anything that isn't in the sources.
If they don't answer it, say only: "Not found in the offline library." """

# Local emergency number: set EMERGENCY_NUMBER (e.g. 112, 999, 000); chat_server.py reads the same variable
EMERGENCY_LINE = "If this could be life-threatening, call %s if you can." % os.environ.get("EMERGENCY_NUMBER", "911")
# Printed only when the question or the top article is about one of these (not for water, food, repairs)
EMERGENCY_WORDS = re.compile(
    r"chok|bleed|blood|hemorrh|haemorrh|chest pain|heart|cardiac|breath|unconscious|faint|seizure|"
    r"stroke|poison|overdose|anaphyla|allerg|drown|cpr|suicid|hypotherm|heat ?stroke|burn|shock|"
    r"snake|sting|bite|head injur|concuss|fractur|broken bone|carbon monoxide",
    re.I)


def http_get(url, timeout=30):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return r.read().decode("utf-8", errors="replace")


def keywords(question):
    words = re.findall(r"[a-zA-Z0-9'-]+", question.lower())
    kept = [w for w in words if w not in STOPWORDS and len(w) > 1]
    return kept or words


def books():
    """Book ids (ZIM file stems) that kiwix-serve is serving."""
    xml = http_get(f"{KIWIX}/catalog/v2/entries?count=100")
    return sorted(set(re.findall(r'href="/content/([^"/]+)"', xml)))


def weight(book):
    for prefix, w in BOOK_WEIGHT.items():
        if book.startswith(prefix):
            return w
    return 0.0


def stem(word):
    """Crude stem so leaking/leaky/leaks and burns/burned match."""
    return word[:5]


def search_pattern(words, term_stems, per_book):
    """Hits for one search pattern from every book, scored against the whole question."""
    pattern = urllib.parse.quote(" ".join(words))
    hits = []
    for book in books():
        url = f"{KIWIX}/search?books.name={book}&pattern={pattern}&format=xml&pageLength={per_book}"
        try:
            xml = http_get(url)
        except Exception:
            continue
        for rank, (title, link) in enumerate(
            re.findall(r"<item>\s*<title>([^<]*)</title>\s*<link>([^<]*)</link>", xml)
        ):
            title_stems = {stem(w) for w in re.findall(r"[a-z0-9]+", title.lower())}
            overlap = len(title_stems & term_stems) / max(len(term_stems), 1)
            score = overlap + weight(book) - 0.05 * rank
            hits.append({"title": title, "link": link, "book": book, "score": score, "overlap": overlap})
    return hits


TOPICS_SYSTEM = """Name the 3 short Wikipedia article titles (1-3 words each) most likely to answer the user's question.
One per line, no numbering, no other text."""

# Worked examples as separate chat turns: in one flat prompt, gemma4:e2b echoed them for every question
TOPICS_EXAMPLES = [
    ("my hand got splashed with boiling water", "Burn\nFirst aid\nScalding"),
    ("the tap water looks brown, can we drink it", "Water purification\nDrinking water\nBoiling"),
]


def no_thinking(model):
    """gpt-oss can't switch thinking off ("think": false is ignored); "low" keeps it short."""
    return "low" if "gpt-oss" in model else False


def topics(question, model):
    """Article titles the model expects to hold the answer, e.g. ham question -> "Food spoilage".
    Everyday wording rarely matches article titles; returns [] if the AI isn't reachable."""
    messages = [{"role": "system", "content": TOPICS_SYSTEM}]
    for q, a in TOPICS_EXAMPLES:
        messages += [{"role": "user", "content": q}, {"role": "assistant", "content": a}]
    messages.append({"role": "user", "content": question})
    think = no_thinking(model)
    body = json.dumps({
        "model": model,
        "messages": messages,
        "stream": False,
        "think": think,
        # Thinking tokens count against num_predict, so a thinking model needs room before it answers
        "options": {"temperature": 0, "num_predict": 1000 if think else 40, "stop": ["\n\n"]},
    }).encode()
    req = urllib.request.Request(f"{OLLAMA}/api/chat", data=body, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            text = json.loads(r.read()).get("message", {}).get("content", "")
    except Exception:
        return []
    titles = []
    for line in text.splitlines():
        line = re.sub(r"^[\s\-*\d.)]+", "", line).strip(" \"'*")
        if 2 < len(line) < 60:
            titles.append(line)
    # Small models sometimes repeat the prompt's examples instead of answering; ignore those
    titles = titles[:3]
    examples = {"burn", "first aid", "scalding", "water purification", "drinking water", "boiling"}
    if titles and all(t.lower() in examples for t in titles):
        return []
    return titles


def exact_articles(titles):
    """Articles whose title is exactly one of the topics ("Nosebleed", "Choking"), best topic first.
    Full-text search ranks these below near misses like "First aid kit", so look them up directly."""
    tried, hits = set(), []
    for i, topic in enumerate(titles):
        # "Heart attack symptoms" -> also "Heart attack"; "Open wounds" -> also "Open wound"
        words = topic.split()
        variants = [topic, topic[:-1] if topic.endswith("s") else topic]
        if len(words) > 1:
            variants.append(" ".join(words[:-1]))
        for title in dict.fromkeys(variants):
            if title.lower() in tried:
                continue
            tried.add(title.lower())
            # A shortened topic of one word ("High" from "High fever") is only trusted in the medical book
            shelves = ("mdwiki",) if title != topic and " " not in title else ("mdwiki", "wikipedia")
            hits += exact_article(title, 2.0 - 0.1 * i - (0 if title == topic else 0.05), shelves)
    return hits


def exact_article(title, score, shelves):
    """The article called exactly `title` in the given books, if any."""
    hits = []
    path = urllib.parse.quote((title[:1].upper() + title[1:]).replace(" ", "_"))
    for book in books():
        if not book.startswith(shelves):
            continue
        try:
            with urllib.request.urlopen(f"{KIWIX}/content/{book}/{path}", timeout=10) as r:
                link = urllib.parse.urlparse(r.geturl()).path  # after redirects, e.g. Nose_bleed -> Nosebleed
        except Exception:
            continue
        name = urllib.parse.unquote(link.rsplit("/", 1)[-1]).replace("_", " ")
        hits.append({"title": name, "link": link, "book": book, "score": score + weight(book), "overlap": 1.0})
    return hits


def search(terms, per_book=4, extra_topics=()):
    """Top hits from every book, scored by title overlap with the terms plus book priority."""
    topic_words = [keywords(t) for t in extra_topics]
    term_stems = {stem(t) for t in terms} | {stem(w) for ws in topic_words for w in ws}
    hits = exact_articles(extra_topics) + search_pattern(terms, term_stems, per_book)
    for ws in topic_words:
        hits += search_pattern(ws, term_stems, 3)
    # The library needs every word to match; long everyday questions often match nothing,
    # so fall back to searching each word on its own
    if not hits and len(terms) > 1:
        for t in terms:
            hits += search_pattern([t], term_stems, 2)
    # Titles sharing no word with the question are dropped unless nothing better exists
    hits.sort(key=lambda h: h["score"], reverse=True)
    if any(h["overlap"] > 0 for h in hits):
        hits = [h for h in hits if h["overlap"] > 0]
    # Same article from two books (e.g. "Burn" in WikiMed and Wikipedia): keep the higher-ranked one
    seen, unique = set(), []
    for h in hits:
        if h["title"].lower() not in seen:
            seen.add(h["title"].lower())
            unique.append(h)
    return unique


class TextExtractor(HTMLParser):
    """Readable text from a Kiwix article: headings, paragraphs and list items."""

    KEEP = {"p", "li", "h1", "h2", "h3", "h4", "dd", "dt"}
    SKIP = {"script", "style", "table", "sup", "nav", "footer"}

    def __init__(self):
        super().__init__()
        self.parts, self.buf, self.keep, self.skip = [], [], 0, 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self.skip += 1
        elif tag in self.KEEP:
            self.keep += 1

    def handle_endtag(self, tag):
        if tag in self.SKIP:
            self.skip = max(0, self.skip - 1)
        elif tag in self.KEEP:
            self.keep = max(0, self.keep - 1)
            text = " ".join("".join(self.buf).split())
            if text:
                self.parts.append(("## " + text) if tag.startswith("h") else text)
            self.buf = []

    def handle_data(self, data):
        if self.keep and not self.skip:
            self.buf.append(data)


def article_text(link, max_chars, query_stems=frozenset()):
    """The article's opening plus the paragraphs that mention the question's words most,
    kept in article order. The useful part ("freezer" in Food safety) is often far below the top."""
    parser = TextExtractor()
    parser.feed(http_get(KIWIX + link))
    parts = parser.parts
    for i, p in enumerate(parts):  # iFixit: the author box and user comments aren't instructions
        if re.match(r"## (Author|\d+ comments?)$", p):
            parts = parts[:i]
            break
    if not query_stems or len("\n".join(parts)) <= max_chars:
        return "\n".join(parts)[:max_chars]
    intro, used, keep = [], 0, set()
    for i, p in enumerate(parts):  # opening paragraphs, up to half the budget
        if used + len(p) > max_chars // 2:
            break
        keep.add(i)
        used += len(p)
    def relevance(i):
        words = {stem(w) for w in re.findall(r"[a-z0-9]+", parts[i].lower())}
        return len(words & query_stems)
    for i in sorted(range(len(parts)), key=relevance, reverse=True):
        if i in keep or relevance(i) == 0:
            continue
        if used + len(parts[i]) > max_chars:
            continue
        keep.add(i)
        used += len(parts[i])
    return "\n".join(parts[i] for i in sorted(keep))


def answer(question, sources, model, think):
    context = "\n\n".join(
        f"[{i}] {s['title']} ({s['book']})\n{s['text']}" for i, s in enumerate(sources, 1)
    )
    body = json.dumps({
        "model": model,
        "stream": True,
        "think": think or no_thinking(model),
        "options": {"temperature": 0, "num_ctx": 8192},  # same question -> same answer
        "messages": [
            {"role": "system", "content": SHORT_PROMPT if re.search(r":[0-3]b", model) else SYSTEM_PROMPT},
            {"role": "user", "content": f"SOURCES:\n{context}\n\nQUESTION: {question}"},
        ],
    }).encode()
    req = urllib.request.Request(f"{OLLAMA}/api/chat", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=900) as r:
        for line in r:
            chunk = json.loads(line)
            print(chunk.get("message", {}).get("content", ""), end="", flush=True)
            if chunk.get("done"):
                print()


def find_cards(question, limit=2):
    """Checked quick-reference cards (cards/*.txt) whose KEYWORDS match the question.
    They print instantly, before the AI, for emergencies where a wrong step is dangerous."""
    here = os.path.dirname(os.path.abspath(__file__))
    folder = next((d for d in (os.path.join(here, "cards"), os.path.join(here, "..", "cards"))
                   if os.path.isdir(d)), None)
    if not folder:
        return []
    q, found = question.lower(), []
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".txt") or name == "README.txt":
            continue
        with open(os.path.join(folder, name), encoding="utf-8") as f:
            text = f.read()
        first, _, body = text.partition("\n")
        if not first.startswith("KEYWORDS:"):
            continue
        hits = sum(1 for kw in first[9:].split(",") if kw.strip() and re.search(r"\b" + re.escape(kw.strip()), q))
        if hits:
            found.append((hits, body.strip()))
    return [body for _, body in sorted(found, key=lambda c: -c[0])[:limit]]


def ask(question, args):
    cards = find_cards(question)
    for card in cards:
        print("\n" + card + "\n")
    if cards:
        print("-" * 62 + "\nFrom the library (the card above comes first if they disagree):")
    terms = keywords(question)
    extra = [] if args.no_topics else topics(question, args.model)
    if extra:
        print("Looking up: " + "; ".join(extra))
    hits = search(terms, extra_topics=extra)
    if not hits:
        print("Nothing found in the offline library.")
        return
    query_stems = frozenset(stem(t) for t in terms)
    # The matching card is source [1] for the AI too, so the answer below it doesn't contradict it
    sources = [{"title": c.splitlines()[0].strip(), "book": "quick-reference card", "link": "", "text": c}
               for c in cards]
    for h in hits:
        if len(sources) == max(args.sources, len(cards) + 2):
            break
        try:
            # The best match gets the most room: 1.6x the budget for [1], 0.8x for the rest
            budget = int(args.chars * (1.6 if not sources else 0.8))
            h["text"] = article_text(h["link"], budget, query_stems)
        except Exception as e:
            print(f"(skipped {h['title']}: {e})", file=sys.stderr)
            continue
        if re.search(r"^Steps\n0$", h["text"], re.M):  # iFixit guide with no steps, only comments
            continue
        sources.append(h)
    if not sources:
        print("Nothing found in the offline library.")
        return

    print("\nSources:")
    for i, s in enumerate(sources, 1):
        print(f"  [{i}] {s['title']}  ({s['book']})  {KIWIX + s['link'] if s['link'] else ''}")
    if args.search_only:
        return
    print(f"\nAnswer ({args.model}):\n")
    if EMERGENCY_WORDS.search(question + " " + sources[0]["title"]):
        print(EMERGENCY_LINE + "\n")
    answer(question, sources, args.model, args.think)


def main():
    global KIWIX, OLLAMA
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("question", nargs="*")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--sources", type=int, default=3, help="articles to read (default 3)")
    p.add_argument("--chars", type=int, default=2500, help="characters taken from each article")
    p.add_argument("--think", action="store_true", help="let the model reason first (slower)")
    p.add_argument("--search-only", action="store_true", help="list articles, no AI answer")
    p.add_argument("--no-topics", action="store_true", help="search the question's own words only (no AI step)")
    p.add_argument("--kiwix", default=KIWIX)
    p.add_argument("--ollama", default=OLLAMA)
    args = p.parse_args()
    KIWIX, OLLAMA = args.kiwix.rstrip("/"), args.ollama.rstrip("/")

    if args.question:
        ask(" ".join(args.question), args)
        return
    while True:
        try:
            # Drop keys pressed while the answer was printing, so they don't garble the next question
            import termios
            termios.tcflush(sys.stdin, termios.TCIFLUSH)
        except Exception:
            pass
        try:
            q = input("\nQuestion (q to quit): ")
        except (EOFError, KeyboardInterrupt):
            break
        q = re.sub(r"\x1b\[[0-9;]*[A-Za-z]|[\x00-\x1f\x7f]", "", q).strip()
        if q.lower() in ("q", "quit", "exit"):
            break
        if q:
            ask(q, args)


if __name__ == "__main__":
    main()
