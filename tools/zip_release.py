#!/usr/bin/env python3
"""zip_release.py <out.zip> <binary>: zips a game binary (keeping the Linux executable bit) with the README."""
import os, stat, sys, zipfile

out, binary = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    info = zipfile.ZipInfo(os.path.basename(binary))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = (stat.S_IMODE(os.stat(binary).st_mode) | stat.S_IFREG) << 16
    with open(binary, "rb") as f:
        z.writestr(info, f.read())
    if os.path.exists("README.md"):
        z.write("README.md", "README.md")
print("wrote", out)
