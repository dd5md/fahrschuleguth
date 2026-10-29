#!/usr/bin/env python3
"""Einmaliger Import aus dem Alt-Repo (fahrschuleguth.de).

Aufruf:  python3 scripts/import_alt.py /pfad/zu/fahrschuleguth.de

Erzeugt optimierte Bilder (WebP + JPG/PNG-Fallback, max. Kantenlaenge begrenzt,
ohne Metadaten) unter source/assets/images/ sowie data/galerie.yml und
data/news.yml. Die Alt-Texte stehen unten und werden von Hand gepflegt.
"""
import os, re, sys, yaml
from PIL import Image

ALT = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "source/assets/images")
A = os.path.join(ALT, "source/assets/images")
S = os.path.join(ALT, "source/statics/images")

def save(src, dest, maxw, fmt="jpg"):
    im = Image.open(src)
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA" if "transparency" in im.info else "RGB")
    if im.width > maxw:
        im = im.resize((maxw, round(im.height * maxw / im.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(os.path.join(OUT, dest)), exist_ok=True)
    base = os.path.join(OUT, dest)
    im.save(base + ".webp", "WEBP", quality=80, method=6)
    if fmt == "png":
        im.save(base + ".png", "PNG", optimize=True)
    else:
        im.convert("RGB").save(base + ".jpg", "JPEG", quality=82, optimize=True, progressive=True)

def slug(n):
    return n.replace(".", "-")

ALTS = {
 "fahrschule": {
  "fahrschule": "Schaufenster der Fahrschule Uli Guth in Bochum-Weitmar",
  "fahrschule_1": "Wartebereich mit blauem Sofa und Tischkicker in der Fahrschule",
  "fahrschule_10": "Fahrlehrer Uli Guth im Büro der Fahrschule",
  "fahrschule_11": "Fahrschüler auf einem Motorrad auf dem Übungsplatz",
  "fahrschule_2": "Schwarzer BMW der Fahrschule mit Fahrlehrer davor",
  "fahrschule_3": "Schwarzer BMW der Fahrschule mit geöffneter Tür im Abendlicht",
  "fahrschule_4": "Zwei Übungsnotebooks in der Fahrschule",
  "fahrschule_5": "Theorieraum mit blauen Stühlen, Tischkicker und Bildern",
  "fahrschule_6": "Theorieraum mit Leinwand und blauen Stühlen",
  "fahrschule_7": "Schwarzer BMW und Motorrad vor der Fahrschule",
  "fahrschule_neu_1": "Theorieraum mit blauen Stühlen und Smartboard",
  "fahrschule_neu_10": "Mann mit Kappe im Eingangsbereich der Fahrschule",
  "fahrschule_neu_2": "Tafel mit Verkehrszeichen an der Wand",
  "fahrschule_neu_3": "Smartboard im Theorieraum mit Bild eines Autos am Strand",
  "fahrschule_neu_4": "Theorieraum mit Smartboard und blauen Stühlen",
  "fahrschule_neu_5": "Sitzecke mit blauem Sofa und Palme in der Fahrschule",
  "fahrschule_neu_6": "Theorieraum von der Seite, im Hintergrund Motorradschutzkleidung",
  "fahrschule_neu_7": "Blaue Stühle im Theorieraum, dahinter ein Motorrad",
  "fahrschule_neu_8": "Theorieraum mit Stuhlreihen und Lautsprechern",
  "fahrschule_neu_9": "Theorieraum mit roter und blauer Beleuchtung",
  "sena_helm_1": "Motorradhelm mit Sena-Funktechnik",
  "sena_helm_2": "Zwei Motorradhelme mit Sena-Funktechnik",
 },
 "fahrzeuge": {
  "BO_UG_9_1": "Cockpit mit Mediendisplay und Lüftungsdüsen der Mercedes A-Klasse",
  "BO_UG_9_2": "Lenkrad und Cockpit der Mercedes A-Klasse",
  "BO_UG_9_3": "Fahrertür der Mercedes A-Klasse von innen",
  "BO_UG_9_4": "Mercedes A-Klasse von vorn mit Kennzeichen BO-UG 9",
  "BO_UG_9_5": "Rücksitz der Mercedes A-Klasse",
  "BO_UG_9_6": "Innenraum der Mercedes A-Klasse mit Blick auf die Sitze",
  "BO_UG_9_7": "Schwarze Mercedes A-Klasse mit AMG-Paket von vorn",
  "BO_UG_9_8": "Schwarze Mercedes A-Klasse schräg von vorn auf dem Hof",
  "BO_UG_9_9": "Kühlergrill der Mercedes A-Klasse mit Stern und Kennzeichen BO-UG 9",
  "BO_UG_9_10": "Scheinwerfer der schwarzen Mercedes A-Klasse",
  "aklasse_neu_1": "Mercedes A-Klasse von vorn im Autohaus",
  "aklasse_neu_2": "Schwarze Mercedes A-Klasse im Autohaus",
  "aklasse_neu_3": "Mann an der geöffneten Tür der Mercedes A-Klasse im Autohaus",
  "aklasse_neu_4": "Mercedes A-Klasse auf Pflaster, schräg von vorn",
  "aklasse_neu_5": "Mercedes A-Klasse auf Pflaster, schräg von hinten",
  "aklasse_neu_6": "Mercedes A-Klasse auf Pflaster von der Seite",
  "aklasse_neu_7": "AMG-Leichtmetallfelge der Mercedes A-Klasse",
  "aklasse_neu_9": "Scheinwerfer der Mercedes A-Klasse mit Schriftzug „total Guth!“",
  "aklasse_neu_10": "Fahrersitz und Cockpit der Mercedes A-Klasse",
  "aklasse_neu_11": "Mediendisplay der Mercedes A-Klasse mit Smartphone-Anbindung",
  "aklasse_neu_12": "Heckansicht der schwarzen Mercedes A-Klasse",
  "mercedes": "Kühlergrill mit Mercedes-Stern und Kennzeichen BO-UG 9",
  "mercedes_2": "Lenkrad mit Mercedes-Stern und digitalem Cockpit",
  "mercedes_3": "Digitales Kombiinstrument mit Navigationskarte",
 },
 "motorraeder": {
  "kawa": "Supermoto-Motorrad in Schwarz und Rot vor einer Wand",
  "kawa2": "Frontpartie eines Supermoto-Motorrads in Rot und Schwarz",
  "kawasaki_1": "Grünes Kawasaki-Motorrad auf Pflaster",
  "kawasaki_12_600px": "Tank eines Kawasaki-Motorrads in Silber und Schwarz",
  "kawasaki_13_600px": "Zwei Motorräder vor dem Schaufenster der Fahrschule",
  "kawasaki_14_600px": "Motorrad von hinten vor der Fahrschule",
  "kawasaki_15_600px": "Frontverkleidung eines Supermoto-Motorrads in Rot und Schwarz",
  "kawasaki_2": "Grünes Kawasaki-Motorrad von hinten",
  "kawasaki_3": "Drei Motorräder vor der Fahrschule",
  "kawasaki_4": "Kawasaki-Motorrad mit Sitzbank und Tank vor dem Schaufenster",
  "kawasaki_5": "Motorräder vor der Fahrschule, im Vordergrund Sitzbank und Tank",
  "kawasaki_6": "Zwei schwarze Motorräder vor der Fahrschule",
  "kawasaki_7": "Grünes Kawasaki-Motorrad von vorn",
  "kawasaki_8": "Grünes Kawasaki-Motorrad mit schwarzem Rahmen",
  "kawasaki_z650s_1": "Frontverkleidung einer Kawasaki Z650 S",
  "kawasaki_z650s_2": "Kawasaki Z650 S mit gelben Akzenten von der Seite",
  "kawasaki_z650s_3": "Kawasaki Z650 S schräg von vorn",
  "kawasaki_z650s_4": "Digitales Kombiinstrument eines Motorrads",
  "motorrad_1": "Supermoto-Motorrad auf Pflaster",
  "motorrad_2": "Federbein und Kette eines Motorrads",
  "motorrad_3": "Frontpartie eines Supermoto-Motorrads vor dem Schaufenster",
 },
}
MONTHS = "Januar Februar März April Mai Juni Juli August September Oktober November Dezember".split()

def listed(name):
    return yaml.safe_load(open(os.path.join(ALT, "data", name + ".yml")))

def bestanden_alt(n):
    m = re.match(r"bestanden_(\d\d)[._](\d{4})_", n) or re.match(r"bestanden_(\d{4})", n)
    mo = re.match(r"bestanden_(\d\d)[._](\d{4})", n)
    if mo:
        return f"Fahrschüler nach bestandener Prüfung, {MONTHS[int(mo.group(1))-1]} {mo.group(2)}"
    return "Fahrschüler nach bestandener Prüfung"

galerie = {}
for group in ("fahrschule", "fahrzeuge", "motorraeder", "bestanden"):
    items = []
    for e in listed(group):
        n = os.path.splitext(os.path.basename(e["src"]))[0]
        n = n.replace("_index", "")
        src = os.path.join(A, "galerie", group, n + ".webp")
        alt = bestanden_alt(n) if group == "bestanden" else ALTS[group].get(n)
        if alt is None:
            sys.exit(f"Alt-Text fehlt: {group}/{n}")
        save(src, f"galerie/{group}/{slug(n)}", 720)
        items.append({"file": f"galerie/{group}/{slug(n)}", "alt": alt})
    galerie[group] = items

# News: Beitraege aus news.htm.erb
t = open(os.path.join(ALT, "source/news.htm.erb")).read()
news_list = [os.path.splitext(os.path.basename(e["src"]))[0] for e in listed("news")]
news = []
for c in t.split("<div class='mdc-card newscard'")[1:]:
    title = re.search(r"newscard__title'>(.*?)</h2>", c).group(1)
    sub = re.search(r"newscard__subtitle'>(.*?)</h4>", c).group(1)
    body = re.search(r"newscard__secondary'>\s*(.*?)\s*</div>", c, re.S).group(1)
    imgs = news_list if "data.news" in c else [os.path.splitext(os.path.basename(i))[0] for i in re.findall(r"image_path\('([^']+)'\)", c)]
    out = []
    for n in imgs:
        d = f"galerie/bestanden/{slug(n)}"
        if not os.path.exists(os.path.join(OUT, d + ".webp")):
            save(os.path.join(A, "galerie/bestanden", n + ".webp"), d, 720)
        out.append({"file": d, "alt": bestanden_alt(n)})
    news.append({"title": title, "subtitle": sub, "text": body, "images": out})

# Einzelbilder (Originale aus statics, wenn vorhanden)
for dest, src, w, fmt in [
    ("hero/a-klasse-schaufenster", S + "/hero/hero_11.jpg", 1400, "jpg"),
    ("hero/a-klasse-front", S + "/hero/hero_44.jpg", 1000, "jpg"),
    ("hero/a-klasse-seite", S + "/hero/hero_16.jpeg", 1000, "jpg"),
    ("bilder/helme", S + "/bilder/guth_index_neu.jpeg", 900, "jpg"),
    ("bilder/tina", S + "/bilder/tina.jpg", 720, "jpg"),
    ("bilder/index-cockpit", S + "/bilder/index_card_neu.jpeg", 800, "jpg"),
    ("bilder/index-kuehlergrill", S + "/bilder/index_card_2.jpg", 800, "jpg"),
    ("bilder/index-fuehrerschein", S + "/bilder/index_card_4.jpg", 800, "jpg"),
    ("bilder/ok", S + "/bilder/ok.png", 128, "png"),
]:
    save(src, dest, w, fmt)

with open(os.path.join(ROOT, "data/galerie.yml"), "w") as f:
    yaml.safe_dump(galerie, f, allow_unicode=True, sort_keys=False, width=200)
with open(os.path.join(ROOT, "data/news.yml"), "w") as f:
    yaml.safe_dump({"posts": news}, f, allow_unicode=True, sort_keys=False, width=200)
print("fertig", {k: len(v) for k, v in galerie.items()}, len(news))
