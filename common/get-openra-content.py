#!/usr/bin/env python3
"""Pre-install OpenRA's free game files (Red Alert, Tiberian Dawn, Dune 2000), so nobody has to
click "Quick Install" in the game while online. Same packages and SHA-1 checks as the game uses.

    python3 common/get-openra-content.py [support-dir]

support-dir defaults to OpenRA's own: %APPDATA%\\OpenRA (Windows),
~/Library/Application Support/OpenRA (macOS), ~/.config/openra (Linux).
On a shared Mac, point it at a shared folder and link each account's Content to it
(mac/setup-account.sh does this for /Users/Shared/Emergency/openra).
"""
import hashlib
import io
import os
import sys
import urllib.request
import zipfile

# mirror list, SHA-1, folder under Content/ (from OpenRA release-20250330 mods/*-content/installer/downloads.yaml)
PACKAGES = [
    ("https://www.openra.net/packages/ra-quickinstall-mirrors.txt", "44241f68e69db9511db82cf83c174737ccda300b", "ra/v2"),
    ("https://www.openra.net/packages/cnc-mirrors.txt", "72f337464963fa37d3688eb03e80eefd33669a3d", "cnc"),
    ("https://www.openra.net/packages/d2k-quickinstall-v3-mirrors.txt", "7bcaa55408a5e6995b43a0d02862c4e8574cf861", "d2k"),
]


def default_dir():
    if sys.platform == "win32":
        return os.path.join(os.environ["APPDATA"], "OpenRA")
    if sys.platform == "darwin":
        return os.path.expanduser("~/Library/Application Support/OpenRA")
    return os.path.expanduser("~/.config/openra")


def main():
    content = os.path.join(sys.argv[1] if len(sys.argv) > 1 else default_dir(), "Content")
    for mirrors, sha1, sub in PACKAGES:
        with urllib.request.urlopen(mirrors, timeout=30) as r:
            urls = r.read().decode().split()
        for url in urls:
            try:
                with urllib.request.urlopen(url, timeout=600) as r:
                    data = r.read()
            except Exception as e:
                print("  %s failed (%s), trying next" % (url, e))
                continue
            if hashlib.sha1(data).hexdigest() != sha1:
                print("  %s: wrong checksum, trying next" % url)
                continue
            dest = os.path.join(content, sub)
            zipfile.ZipFile(io.BytesIO(data)).extractall(dest)
            print("OK  %s -> %s" % (sub, dest))
            break
        else:
            print("FAILED  %s" % sub)


if __name__ == "__main__":
    main()
