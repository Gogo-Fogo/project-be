#!/usr/bin/env python3
"""Check every .zim in a library folder against Kiwix's published SHA-256. Read-only.

    python3 common/verify-library.py /path/to/library

Takes about 10 minutes per 70 GB. Needs internet (to fetch the checksums).
"""
import hashlib
import os
import sys
import urllib.request

FOLDERS = {"wikipedia": "wikipedia", "wikivoyage": "wikivoyage", "ifixit": "ifixit"}


def main():
    lib = sys.argv[1] if len(sys.argv) > 1 else "."
    zims = sorted((f for f in os.listdir(lib) if f.endswith(".zim")), key=lambda f: os.path.getsize(os.path.join(lib, f)))
    bad = 0
    for name in zims:
        folder = FOLDERS.get(name.split("_")[0], "other")
        try:
            with urllib.request.urlopen("https://download.kiwix.org/zim/%s/%s.sha256" % (folder, name), timeout=60) as r:
                want = r.read().decode().split()[0].lower()
        except Exception:
            want = ""
        h = hashlib.sha256()
        with open(os.path.join(lib, name), "rb") as f:
            for chunk in iter(lambda: f.read(1 << 22), b""):
                h.update(chunk)
        status = "NO CHECKSUM" if len(want) != 64 else ("OK" if h.hexdigest() == want else "MISMATCH")
        bad += status == "MISMATCH"
        print("%-48s %s" % (name, status), flush=True)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
