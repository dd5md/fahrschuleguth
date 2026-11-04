#!/usr/bin/env python3
"""Neue Fotos für die Galerie aufbereiten und eintragen.

Beispiel (Fotos der Bestandenen vom November 2026):
    python3 scripts/add_photos.py ~/Desktop/neue-fotos

Was das Skript macht:
  * liest alle Bilder (JPG, PNG, WebP, HEIC/HEIF falls pillow-heif installiert ist) aus dem Ordner,
  * dreht sie richtig (Handy-Fotos), entfernt ALLE Metadaten (Kamera, Datum, GPS),
  * erzeugt je Foto WebP + JPG (längste Seite 1280 px) und eine kleine WebP-Variante (-640) fürs Handy,
  * legt sie unter source/assets/images/galerie/<kategorie>/ ab und
    nennt sie <kategorie>_<MM>-<JJJJ>_<Nr> (Nummern laufen weiter),
  * trägt sie OBEN in data/galerie.yml ein (neueste zuerst; die Startseite zeigt die ersten 8).

Optionen:
  --monat 11 --jahr 2026   Monat/Jahr der Fotos (Standard: heute)
  --kategorie bestanden    bestanden (Standard), fahrschule, fahrzeuge, motorraeder
  --alt "Text"             eigener Alt-Text für alle Fotos dieses Aufrufs
  --trocken                nur anzeigen, nichts schreiben
  --verschieben            Originale nach dem Import in den Unterordner "fertig" verschieben

Danach: bundle exec middleman server (ansehen), committen, pushen.
Hinweis: Nur Fotos verwenden, bei denen die abgebildeten Personen zugestimmt haben.
"""
import argparse, datetime, glob, os, re, shutil, sys
from PIL import Image, ImageOps

try:
    import pillow_heif  # optional, für iPhone-Fotos (HEIC)
    pillow_heif.register_heif_opener()
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MONATE = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
ENDUNGEN = (".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif")
KATEGORIEN = ("bestanden", "fahrschule", "fahrzeuge", "motorraeder")
MAX_SEITE = 1280
KLEIN = 640


def alt_standard(kategorie, monat, jahr):
    if kategorie == "bestanden":
        return f"Fahrschüler nach bestandener Prüfung, {MONATE[monat - 1]} {jahr}"
    return "Foto der Fahrschule Guth"


def naechste_nummer(bilder_dir, praefix):
    nr = 0
    for f in glob.glob(os.path.join(bilder_dir, f"{praefix}_*.webp")):
        m = re.search(rf"{re.escape(praefix)}_(\d+)(?:-640)?\.webp$", f)
        if m:
            nr = max(nr, int(m.group(1)))
    return nr + 1


def aufbereiten(quelle, ziel_ohne_endung):
    with Image.open(quelle) as im:
        im = ImageOps.exif_transpose(im)  # Drehung aus den Metadaten anwenden
        if im.mode not in ("RGB", "RGBA"):
            im = im.convert("RGB")
        if max(im.size) > MAX_SEITE:
            faktor = MAX_SEITE / max(im.size)
            im = im.resize((round(im.width * faktor), round(im.height * faktor)), Image.LANCZOS)
        rgb = im.convert("RGB")
        # Speichern ohne exif=/icc_profile= entfernt alle Metadaten
        rgb.save(ziel_ohne_endung + ".webp", "WEBP", quality=80, method=6)
        rgb.save(ziel_ohne_endung + ".jpg", "JPEG", quality=82, optimize=True, progressive=True)
        if im.width > KLEIN:
            klein = rgb.resize((KLEIN, round(rgb.height * KLEIN / rgb.width)), Image.LANCZOS)
            klein.save(ziel_ohne_endung + "-640.webp", "WEBP", quality=78, method=6)
        return im.size


def eintragen(yaml_pfad, kategorie, eintraege):
    """Fügt die Einträge oben in die Liste <kategorie>: ein (Text-Einfügung, übrige Datei bleibt unverändert)."""
    text = open(yaml_pfad, encoding="utf-8").read()
    m = re.search(rf"^{kategorie}:\s*\n", text, re.M)
    if not m:
        sys.exit(f"Kategorie '{kategorie}' fehlt in {yaml_pfad}")
    block = "".join(f"- file: {datei}\n  alt: {alt}\n" for datei, alt in eintraege)
    text = text[: m.end()] + block + text[m.end():]
    open(yaml_pfad, "w", encoding="utf-8").write(text)


def yaml_text(alt):
    # Alt-Texte quoten, wenn Sonderzeichen enthalten sind
    return f"'{alt}'" if re.search(r"[:#'\"\[\]{}&*!|>%@`]", alt) else alt


def main():
    ap = argparse.ArgumentParser(description="Neue Galerie-Fotos aufbereiten und eintragen")
    ap.add_argument("ordner")
    ap.add_argument("--monat", type=int, default=datetime.date.today().month)
    ap.add_argument("--jahr", type=int, default=datetime.date.today().year)
    ap.add_argument("--kategorie", default="bestanden", choices=KATEGORIEN)
    ap.add_argument("--alt")
    ap.add_argument("--trocken", action="store_true")
    ap.add_argument("--verschieben", action="store_true")
    ap.add_argument("--root", default=ROOT, help=argparse.SUPPRESS)
    a = ap.parse_args()

    if not 1 <= a.monat <= 12:
        sys.exit("Monat muss 1 bis 12 sein")
    quellen = sorted(f for f in glob.glob(os.path.join(os.path.expanduser(a.ordner), "*"))
                     if f.lower().endswith(ENDUNGEN) and os.path.isfile(f))
    if not quellen:
        sys.exit(f"Keine Bilder gefunden in {a.ordner} ({', '.join(ENDUNGEN)})")

    bilder_dir = os.path.join(a.root, "source/assets/images/galerie", a.kategorie)
    yaml_pfad = os.path.join(a.root, "data/galerie.yml")
    os.makedirs(bilder_dir, exist_ok=True)
    praefix = f"{a.kategorie}_{a.monat:02d}-{a.jahr}"
    nr = naechste_nummer(bilder_dir, praefix)
    alt = a.alt or alt_standard(a.kategorie, a.monat, a.jahr)

    eintraege = []
    for q in quellen:
        name = f"{praefix}_{nr}"
        ziel = os.path.join(bilder_dir, name)
        if a.trocken:
            print(f"[trocken] {os.path.basename(q)} -> galerie/{a.kategorie}/{name}")
        else:
            try:
                groesse = aufbereiten(q, ziel)
            except Exception as e:
                print(f"FEHLER bei {os.path.basename(q)}: {e}")
                continue
            kb = os.path.getsize(ziel + ".webp") // 1024
            print(f"ok  {os.path.basename(q)} -> {name} ({groesse[0]}x{groesse[1]}, WebP {kb} KB)")
        eintraege.append((f"galerie/{a.kategorie}/{name}", yaml_text(alt)))
        nr += 1

    if a.trocken or not eintraege:
        return
    # neueste zuerst: in der Reihenfolge der Dateien oben einfügen
    eintragen(yaml_pfad, a.kategorie, eintraege)
    if a.verschieben:
        fertig = os.path.join(os.path.expanduser(a.ordner), "fertig")
        os.makedirs(fertig, exist_ok=True)
        for q in quellen:
            shutil.move(q, os.path.join(fertig, os.path.basename(q)))
    print(f"\n{len(eintraege)} Foto(s) eingetragen in data/galerie.yml ({a.kategorie}), Alt-Text: {alt}")
    print("Nächste Schritte: ansehen (bundle exec middleman server), dann committen und pushen.")


if __name__ == "__main__":
    main()
