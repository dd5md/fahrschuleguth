# Fahrschule Guth – fahrschuleguth.de

Neuaufbau der Website der Fahrschule Uli Guth (Bochum-Weitmar).
Middleman 4 · ERB (Layout + Partials) · Tailwind CSS 4 · daisyUI 5 · `external_pipeline` (Tailwind CLI, kein Sprockets).
Inhalte und URLs stammen aus dem Alt-Repo `dd5md/fahrschuleguth.de`, Stack und Design aus `dd5md/dd5md.de`.

## Setup

```bash
export LANG=C.UTF-8        # ohne UTF-8 bricht Middleman ab
bundle install
npm install
```

## Entwicklung / Build

```bash
bundle exec middleman server   # startet zusätzlich `tailwindcss --watch`
bundle exec middleman build    # minifiziertes CSS + statische Seite in build/
```

Hinweis: In manchen Containern findet `bundle exec middleman` das Executable nicht (Ruby-Shim). Dann hilft
`BUNDLE_GEMFILE=$PWD/Gemfile /opt/rbenv/versions/3.3.6/bin/ruby -S bundle exec /opt/rbenv/versions/3.3.6/bin/middleman build`.
Die Site-URL lässt sich per `SITE_URL=… middleman build` überschreiben (Standard `https://fahrschuleguth.de`).

## Struktur

| Pfad | Zweck |
| --- | --- |
| `config.rb` | Middleman-Config (`external_pipeline`, `directory_indexes`) |
| `tailwind.config.js`, `source/assets/stylesheets/site.src.css` | Tailwind-/daisyUI-Setup, Themes `guth-dark` (Standard) und `guth-light`; daisyUI wird per `@plugin` registriert |
| `source/layouts/layout.erb` | Haupt-Layout |
| `source/partials/` | `_head`, `_header`, `_page_header`, `_hours`, `_footer` |
| `source/*.html.erb`, `source/ueberuns/`, `source/galerie/` | Seiten |
| `source/assets/` | `images/`, `stylesheets/`, `javascripts/` (Theme-Umschalter, Lightbox), `fonts/` |
| `source/.htaccess` | unverändert aus der Altseite (HTTPS/WWW-Redirect, Caching, 404) |
| `data/site.yml` | Name, Adresse, Kontakte, Öffnungszeiten, Navigation, Geo |
| `data/preise.yml`, `data/links.yml`, `data/news.yml`, `data/galerie.yml` | Preise, Links/Downloads/Videos, News, Galerien samt Alt-Texten |
| `lib/site_helpers.rb` | Meta-Tags, JSON-LD, `picture_tag`, Icons, Galerie-Raster |
| `scripts/import_alt.py` | einmaliger Bild-/Daten-Import aus dem Alt-Repo (Pillow) |

### Bilder
`picture_tag "pfad/name"` bindet `name.webp` plus Fallback ein (`name.png` falls vorhanden, sonst `name.jpg`),
inkl. `width`/`height`. Die Bilder sind verkleinert (max. 720–1400 px) und ohne Metadaten.
Abweichung von der Vorgabe „PNG + WebP“: Für Fotos ist der Fallback JPG (PNG wäre bei ~270 Fotos ein Vielfaches größer); PNG nur für Grafik (`bilder/ok`).

### Design
Dunkel als Standard, Umschalter Dark/Light mit `localStorage`. Akzent: Signal-Gelb/Amber (Verkehrs- und Fahrschul-Beschilderung, passt zur gelb-roten Ladenfront, sehr guter Kontrast auf dunklem Grund), Zweitfarbe Blau (blaue Stühle im Theorieraum, Farbe der Altseite).

### SEO
Semantisches HTML5, Title/Meta wie Alt (Seitenname • Site-Titel), canonical, Open Graph/Twitter, `sitemap.xml`, `robots.txt`, `llms.txt`,
JSON-LD `@graph` mit `DrivingSchool`/`LocalBusiness` (Adresse, Telefon, Öffnungszeiten, Geo), `WebSite`, `WebPage`, `BreadcrumbList`.
Keine Bewertungen und kein `FAQPage`, weil die Altseite weder Bewertungen noch Fragen/Antworten enthält.

## URLs / Weiterleitungen
Alle URLs der Altseite bleiben identisch (Verzeichnis-URLs mit Slash): `/`, `/ueberuns/`, `/ueberuns/preise/`, `/ueberuns/links/`, `/ueberuns/downloads/`, `/galerie/`, `/galerie/bestanden/`, `/galerie/fahrzeuge/`, `/galerie/motorraeder/`, `/galerie/videos/`, `/news/`, `/kontakt/`, `/impressum/`, `/404.html`.
Es sind daher keine Weiterleitungen nötig. Einzige Abweichung: Das Alt-Menü verlinkte `/galerie/bestanden` ohne Slash – das wird vom Webserver auf `/galerie/bestanden/` umgeleitet.

## Offene Punkte
- [ ] **Datenschutzerklärung fehlt** (auch in der Altseite nicht vorhanden); rechtlich nötig, Text muss vom Inhaber/Anwalt kommen.
- [ ] **PDFs fehlen**: `/assets/files/checkliste.pdf`, `flyer.pdf`, `fuehrerschein_mit_17_anlage_1.pdf`, `…_2.pdf` sind im Alt-Repo nicht enthalten (kamen aus einem Ordner `statics/files`, der nicht eingecheckt ist). In `source/assets/files/` ablegen.
- [ ] Widerspruch in den Altseiten-Texten: Meta-Description „über 25 Jahren“, Startseitentext „über 30 Jahren“ – beides unverändert übernommen, bitte klären.
- [ ] Preisliste trägt „Stand April 2022“ – Aktualität prüfen (Preisaushang).
- [ ] Tippfehler der Altseite bewusst unverändert: „Theorieuntericht“, „Neuste Sena Funk Technik“, „Sebtember 2021“, „Gallerie“.
- [ ] Fotos zeigen erkennbare Fahrschüler, News nennen Vornamen: Einwilligungen prüfen.
- [ ] Alt-Texte der Galerie-Bilder wurden beschreibend ergänzt; „Bestanden“-Bilder haben generische Alt-Texte mit Monat/Jahr.
- [ ] Kein eigenes Logo übernommen (Wortmarke als Text, `favicon.svg` neu); ggf. Original-Logo liefern. OG-Bild ist neu aus einem Foto generiert.
- [ ] Alt-Features nicht übernommen: Header-Slider/Typed-Text, Bilder-Slider (75 Fotos), Material-Icons-Font, Google-Plus/Facebook-App-ID/Twitter-Meta, Leaflet-Karte (jetzt OSM-Einbettung), `sitemap_ping`. Videos nutzen `youtube-nocookie.com`.
- [ ] Facebook-Link `https://www.facebook.com/fahrschuleguth` aus der Alt-Meta als `sameAs`/Footer übernommen – prüfen, ob noch aktuell.
- [ ] Per-Seiten-Meta-Descriptions: Startseite unverändert, Unterseiten neu aus vorhandenen Seitenfakten formuliert (Alt nutzte überall dieselbe).
- [ ] Der `<404>`-Text ist neu (Alt war grafisch); Deployment: `build/` auf den Apache-Webserver (`.htaccess` liegt bei).
