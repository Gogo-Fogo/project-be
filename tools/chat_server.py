#!/usr/bin/env python3
"""Emergency chat page: a small offline web page in front of ask.py.

    python3 chat_server.py --model gemma4:12b     # then open http://127.0.0.1:8090

Each question runs ask.py once (same search, cards, rules and answer as the terminal), and the
answer streams into the page. One plain page, no frameworks, no animations, nothing running while
idle, so it costs almost no battery beyond the AI itself. Standard library only (Python 3.9+).
"""
import argparse
import codecs
import json
import os
import re
import subprocess
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ASK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ask.py")
OLLAMA = "http://127.0.0.1:11434"
KIWIX = "http://127.0.0.1:8080"

# Models offered in the page, in this order, if installed. The big and gpt-oss models are left out
# on purpose: the big ones can freeze the PC and gpt-oss adds advice that isn't in the library.
FAMILY_MODELS = [
    ("gemma4:12b", "Best (PC)"),
    ("qwen3.5:9b", "Careful"),
    ("qwen3.5:4b", "Balanced"),
    ("qwen3.5:2b-q4_K_M", "Low battery"),
]

SOURCE_LINE = re.compile(r"^\s+\[(\d+)\] (.*?)  \((.*?)\)  ?(\S*)\s*$")
# Local emergency number: set EMERGENCY_NUMBER (e.g. 112, 999, 000); chat_server.py reads the same variable
EMERGENCY_LINE = "If this could be life-threatening, call %s if you can." % os.environ.get("EMERGENCY_NUMBER", "911")


def installed_models():
    try:
        with urllib.request.urlopen(OLLAMA + "/api/tags", timeout=5) as r:
            return {m["name"] for m in json.load(r)["models"]}
    except Exception:
        return set()


class Handler(BaseHTTPRequestHandler):
    default_model = "qwen3.5:4b"

    def log_message(self, *args):  # keep the window quiet
        pass

    def send_body(self, code, body, ctype):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/":
            self.send_body(200, PAGE, "text/html; charset=utf-8")
        elif self.path == "/models":
            have = installed_models()
            models = [{"name": n, "label": l} for n, l in FAMILY_MODELS if n in have]
            if self.default_model not in [m["name"] for m in models]:
                models.insert(0, {"name": self.default_model, "label": "Default"})
            self.send_body(200, json.dumps({"models": models, "default": self.default_model,
                                            "library": KIWIX}), "application/json")
        else:
            self.send_body(404, "not found", "text/plain")

    def do_POST(self):
        if self.path != "/ask":
            return self.send_body(404, "not found", "text/plain")
        try:
            req = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            question = " ".join(str(req.get("question", "")).split())[:500]
            model = str(req.get("model") or self.default_model)
        except Exception:
            return self.send_body(400, "bad request", "text/plain")
        if not question:
            return self.send_body(400, "empty question", "text/plain")

        # One JSON event per line, streamed until ask.py finishes (connection closes at the end)
        self.send_response(200)
        self.send_header("Content-Type", "application/x-ndjson")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        proc = subprocess.Popen([sys.executable, "-u", ASK, "--model", model, question],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                env=dict(os.environ, PYTHONIOENCODING="utf-8"))
        try:
            self.relay(proc)
        except (BrokenPipeError, ConnectionResetError):
            pass  # the Stop button closed the page's request: stop the AI too
        finally:
            if proc.poll() is None:
                proc.kill()
            proc.wait()

    def emit(self, **event):
        self.wfile.write((json.dumps(event) + "\n").encode("utf-8"))
        self.wfile.flush()

    def relay(self, proc):
        """Turn ask.py's terminal output into events: card, status, source, emergency, answer."""
        decoder = codecs.getincrementaldecoder("utf-8")(errors="replace")
        pending, card, in_answer = "", [], False
        head = ""  # start of the answer, held back until we know whether it is the 911 line
        while True:
            data = os.read(proc.stdout.fileno(), 4096)
            pending += decoder.decode(data, final=not data).replace("\r", "")  # Windows writes \r\n
            # Before the answer: whole lines (cards, "Looking up", sources)
            while not in_answer and "\n" in pending:
                line, pending = pending.split("\n", 1)
                m = SOURCE_LINE.match(line)
                if line.startswith("Looking up: "):
                    self.emit(type="status", text=line)
                elif m:
                    self.emit(type="source", n=int(m.group(1)), title=m.group(2),
                              book=m.group(3), url=m.group(4))
                elif line.startswith("Answer ("):
                    in_answer = True
                elif line.startswith("From the library") or re.match(r"^-{20,}$", line) or line == "Sources:":
                    if card:
                        self.emit(type="card", text="\n".join(card).strip())
                        card = []
                elif "Nothing found in the offline library" in line:
                    self.emit(type="answer", text=line)
                elif line.strip() or card:
                    card.append(line)
            # The answer itself: streamed as it arrives
            if in_answer and pending:
                if head is None:
                    self.emit(type="answer", text=pending)
                else:
                    head += pending.lstrip("\n") if not head else pending
                    if len(head) >= len(EMERGENCY_LINE) or not data:
                        if head.startswith(EMERGENCY_LINE):
                            self.emit(type="emergency", text=EMERGENCY_LINE)
                            head = head[len(EMERGENCY_LINE):].lstrip("\n")
                        if head:
                            self.emit(type="answer", text=head)
                        head = None
                pending = ""
            if not data:
                break
        if card:
            self.emit(type="card", text="\n".join(card).strip())
        if proc.wait() != 0:
            err = proc.stderr.read().decode("utf-8", "replace").strip().splitlines()
            self.emit(type="error", text=err[-1] if err else "The AI stopped unexpectedly.")
        self.emit(type="done")


PAGE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Emergency Help</title>
<style>
:root { --bg:#f6f5f2; --panel:#fff; --text:#1d1d1f; --muted:#6b6b70; --line:#e2e0db;
  --accent:#1f5fbf; --card:#fff7e0; --card-line:#e8c96a; --red:#b3261e; --red-bg:#fdecea; }
@media (prefers-color-scheme: dark) { :root { --bg:#111214; --panel:#1b1c1f; --text:#ececee;
  --muted:#9a9aa2; --line:#2c2d31; --accent:#7fb0ff; --card:#2a2412; --card-line:#7a6526;
  --red:#ff8a80; --red-bg:#3a1714; } }
* { box-sizing:border-box }
html,body { margin:0; height:100% }
body { background:var(--bg); color:var(--text); font:17px/1.55 -apple-system, "Segoe UI", system-ui, sans-serif;
  display:flex; flex-direction:column }
header { display:flex; align-items:center; gap:12px; padding:12px 16px; border-bottom:1px solid var(--line);
  background:var(--panel); flex-wrap:wrap }
header h1 { font-size:18px; margin:0; flex:1; min-width:160px }
header h1 small { display:block; font-size:13px; font-weight:400; color:var(--muted) }
select, button, a.btn { font:inherit; font-size:15px; border-radius:8px; border:1px solid var(--line);
  background:var(--panel); color:var(--text); padding:7px 12px; text-decoration:none; cursor:pointer }
main { flex:1; overflow-y:auto; padding:16px }
.wrap { max-width:760px; margin:0 auto }
.intro { color:var(--muted); font-size:15px }
.chips { display:flex; flex-wrap:wrap; gap:8px; margin:12px 0 4px }
.chips button { font-size:14px; padding:6px 12px; border-radius:16px }
.q { margin:22px 0 8px; font-weight:600; font-size:18px }
.status { color:var(--muted); font-size:14px; margin:4px 0 }
.card { background:var(--card); border:1px solid var(--card-line); border-radius:10px; padding:12px 14px;
  white-space:pre-wrap; margin:8px 0; font-size:16px }
.card::before { content:"Checked quick-reference card"; display:block; font-size:12px; font-weight:700;
  text-transform:uppercase; letter-spacing:.04em; color:var(--muted); margin-bottom:6px }
.emergency { background:var(--red-bg); color:var(--red); border-radius:10px; padding:10px 14px;
  font-weight:700; margin:8px 0 }
.answer { background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:4px 16px; margin:8px 0 }
.answer:empty { display:none }
.answer ul, .answer ol { padding-left:22px } .answer h3 { font-size:17px; margin:14px 0 4px }
.answer sup a { color:var(--accent); text-decoration:none; font-weight:600 }
.sources { font-size:14px; margin:6px 0 0; padding:0; list-style:none }
.sources li { margin:2px 0 } .sources a { color:var(--accent) } .sources span { color:var(--muted) }
.error { color:var(--red) }
footer { border-top:1px solid var(--line); background:var(--panel); padding:12px 16px }
form { max-width:760px; margin:0 auto; display:flex; gap:8px }
textarea { flex:1; font:inherit; resize:none; border:1px solid var(--line); border-radius:10px; padding:10px 12px;
  background:var(--bg); color:var(--text); height:52px }
form button { min-width:84px; background:var(--accent); color:#fff; border:0; font-weight:600 }
.note { max-width:760px; margin:6px auto 0; font-size:12px; color:var(--muted) }
</style></head>
<body>
<header>
  <h1>Emergency Help <small>Answers only from the offline library &middot; works without internet</small></h1>
  <select id="model" title="AI model"></select>
  <a class="btn" id="lib" href="http://127.0.0.1:8080" target="_blank">Open library</a>
</header>
<main id="log"><div class="wrap">
  <p class="intro">Ask in plain words. The answer lists the articles it used &mdash; tap them to read more.
  For medical questions, read the cited article too.</p>
  <div class="chips" id="chips"></div>
  <div id="items"></div>
</div></main>
<footer>
  <form id="f"><textarea id="q" placeholder="e.g. someone is bleeding badly from the leg" autofocus></textarea>
  <button id="go">Ask</button></form>
  <div class="note">The AI can be wrong. Call 911 if you can. Each question is answered on its own.</div>
</footer>
<script>
const $ = s => document.querySelector(s);
const EXAMPLES = ["Someone is bleeding badly", "How do I do CPR?", "Treating a burn",
  "Make water safe to drink", "Signs of hypothermia", "Carbon monoxide symptoms"];
let busy = null;

fetch("/models").then(r => r.json()).then(d => {
  // Always start on the launcher's model ("Ask (low battery)" picks the small one), not a remembered choice
  const sel = $("#model");
  for (const m of d.models) sel.add(new Option(m.label + " – " + m.name, m.name));
  sel.value = d.default;
  $("#lib").href = d.library;
});
for (const t of EXAMPLES) {
  const b = document.createElement("button"); b.type = "button"; b.textContent = t;
  b.onclick = () => { $("#q").value = t; ask(); }; $("#chips").appendChild(b);
}
$("#f").onsubmit = e => { e.preventDefault(); busy ? busy.abort() : ask(); };
$("#q").onkeydown = e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); if (!busy) ask(); } };

const esc = s => s.replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
function md(text, links) {   // tiny Markdown: headings, bold, lists, [n] citations
  const out = []; let list = null;
  const inline = s => esc(s).replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(\S.*?)\*/g, "<i>$1</i>")
    .replace(/\[(\d+)\]/g, (m, n) => links[n] ? `<sup><a href="${links[n]}" target="_blank">[${n}]</a></sup>` : `<sup>[${n}]</sup>`);
  for (const raw of text.split("\n")) {
    const line = raw.trimEnd(), ul = line.match(/^\s*[-*•]\s+(.*)/), ol = line.match(/^\s*\d+[.)]\s+(.*)/);
    const kind = ul ? "ul" : ol ? "ol" : null;
    if (list && kind !== list) { out.push(`</${list}>`); list = null; }
    if (kind) { if (!list) { out.push(`<${kind}>`); list = kind; } out.push(`<li>${inline((ul || ol)[1])}</li>`); }
    else if (/^#{1,4}\s/.test(line)) out.push(`<h3>${inline(line.replace(/^#+\s*/, ""))}</h3>`);
    else if (/^-{3,}$/.test(line)) out.push("<hr>");
    else if (line) out.push(`<p>${inline(line)}</p>`);
  }
  if (list) out.push(`</${list}>`);
  return out.join("");
}

async function ask() {
  const question = $("#q").value.trim(); if (!question) return;
  $("#q").value = ""; $("#chips").style.display = "none";
  const box = document.createElement("section");
  box.innerHTML = `<div class="q"></div><div class="status">Searching the library…</div>
    <div class="cards"></div><div class="emerg"></div><div class="answer"></div><ul class="sources"></ul>`;
  box.querySelector(".q").textContent = question;
  $("#items").appendChild(box); box.scrollIntoView();
  const status = box.querySelector(".status"), ansEl = box.querySelector(".answer");
  const links = {}; let answer = "", timer = null, started = Date.now();
  const tick = setInterval(() => { if (!answer) status.dataset.t = Math.round((Date.now() - started) / 1000) + " s";
    status.textContent = (status.dataset.base || "Searching the library…") + " " + (status.dataset.t || ""); }, 1000);
  const render = () => { timer = null; ansEl.innerHTML = md(answer, links); };
  busy = new AbortController(); $("#go").textContent = "Stop";
  try {
    const r = await fetch("/ask", {method: "POST", signal: busy.signal,
      body: JSON.stringify({question, model: $("#model").value})});
    const reader = r.body.getReader(), dec = new TextDecoder(); let buf = "";
    for (;;) {
      const {value, done} = await reader.read(); if (done) break;
      buf += dec.decode(value, {stream: true});
      let i; while ((i = buf.indexOf("\n")) >= 0) {
        const ev = JSON.parse(buf.slice(0, i)); buf = buf.slice(i + 1);
        if (ev.type === "status") status.dataset.base = ev.text + " …";
        else if (ev.type === "card") { const c = document.createElement("div"); c.className = "card";
          const [title, ...rest] = ev.text.split("\n").filter(l => !/^=+$/.test(l.trim()));
          const b = document.createElement("b"); b.textContent = title;
          c.append(b, "\n" + rest.join("\n")); box.querySelector(".cards").appendChild(c); }
        else if (ev.type === "source") { if (ev.url) links[ev.n] = ev.url;
          const li = document.createElement("li");
          li.innerHTML = `[${ev.n}] ` + (ev.url ? `<a target="_blank" href="${esc(ev.url)}">${esc(ev.title)}</a>` : esc(ev.title)) +
            ` <span>(${esc(ev.book)})</span>`;
          box.querySelector(".sources").appendChild(li); status.dataset.base = "Reading the articles…"; }
        else if (ev.type === "emergency") box.querySelector(".emerg").innerHTML = `<div class="emergency">${esc(ev.text)}</div>`;
        else if (ev.type === "answer") { answer += ev.text; status.dataset.base = "Writing the answer…";
          if (!timer) timer = setTimeout(render, 200); }   // redraw at most 5x a second
        else if (ev.type === "error") { status.innerHTML = `<span class="error">${esc(ev.text)}</span>`; }
      }
    }
    status.style.display = "none";
  } catch (e) {
    status.textContent = e.name === "AbortError" ? "Stopped." : "Could not reach the AI. Is Emergency started?";
  } finally {
    clearInterval(tick); if (timer) clearTimeout(timer); render();
    busy = null; $("#go").textContent = "Ask"; $("#q").focus();
  }
}
</script>
</body></html>
"""
PAGE = PAGE.replace("Call 911", "Call " + os.environ.get("EMERGENCY_NUMBER", "911"))


def main():
    global OLLAMA, KIWIX
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--model", default="qwen3.5:4b", help="model selected when the page opens")
    p.add_argument("--port", type=int, default=8090)
    p.add_argument("--ollama", default=OLLAMA)
    p.add_argument("--kiwix", default=KIWIX)
    args = p.parse_args()
    OLLAMA, KIWIX = args.ollama.rstrip("/"), args.kiwix.rstrip("/")
    Handler.default_model = args.model
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Emergency chat: http://127.0.0.1:{args.port}  (close this window to stop it)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
