#!/usr/bin/env python3
"""Erzeugt kleinere WebP-Varianten (<name>-640.webp) für responsive Bilder (srcset).

Aufruf:  python3 scripts/make_variants.py hero/a-klasse-seite galerie/fahrzeuge/aklasse_neu_4 ...
"""
import os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(ROOT, "source/assets/images")
for name in sys.argv[1:]:
    im = Image.open(os.path.join(BASE, name + ".webp"))
    if im.width <= 640:
        print("übersprungen (schon klein):", name); continue
    out = im.resize((640, round(im.height * 640 / im.width)), Image.LANCZOS)
    out.save(os.path.join(BASE, name + "-640.webp"), "WEBP", quality=78, method=6)
    print("ok", name, out.size, os.path.getsize(os.path.join(BASE, name + "-640.webp")) // 1024, "KB")
