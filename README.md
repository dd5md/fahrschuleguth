# Fahrschule Guth – fahrschuleguth.de

Neuaufbau der Website der Fahrschule Uli Guth (Bochum-Weitmar).
Middleman 4 · ERB (Layout + Partials) · Tailwind CSS 4 · daisyUI 5 · `external_pipeline` (Tailwind CLI, kein Sprockets).
Inhalte und URLs stammen aus dem Alt-Repo `dd5md/fahrschuleguth.de`, der Stack aus `dd5md/dd5md.de`; das Design ist eigenständig (siehe unten).

## Setup

```bash
export LANG=C.UTF-8        # ohne UTF-8 bricht Middleman ab
bundle install
npm install
```

## Entwicklung / Build

```bash
bundle exec middleman server   # startet zusätzlich `tailwindcss --watch=always` (ohne `always` bricht der Watcher mit `read EIO` ab)
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
Bewusst **kein** Nachbau der Altseite und nicht das Demo-Layout von dd5md.de, sondern ein eigenes Konzept (Briefing vom 30.10.2026):
- Dunkelgrau (Graphit, nicht schwarz), Limette (Primär, Aktionen) und Orange (Sekundär, Hervorhebungen; Farben #c4ff4e und #fcb900), kein Rosa; Dark als Standard, Umschalter Hell/Dunkel (`localStorage`).
- Sehr große weiße Überschriften mit engem Zeichenabstand (Inter Tight, selbst gehostet, nur Latin-Teilsatz). Farbverlauf in der Schrift nur für einzelne Wörter.
- Kein Hero-Foto-Block: Das Auto-Foto ist weich ausgeblendet im Hintergrund. Danach ein Kachel-Layout (Bento) mit Auto, 30+ Jahre, Klassen, Preise, Zeiten, Uli, Standort, Anmelden.
- Reihenfolge der Startseite nach dem, was Besucher wissen wollen: Fahrschule/Auto, Klassen, Dein erster Fahrtag, Preise, Reform 2027, bestanden, FAQ, Kontakt.
- Schnellauswahl (Suchleiste mit Themen, `data/search.yml`) ohne KI und ohne Server; Chips funktionieren auch ohne JavaScript.
- Maskottchen (Kopf von Uli) als leichte CSS-Animation, startet erst nach dem Laden (`.is-loaded`) und respektiert `prefers-reduced-motion`.
- Themes `guth-dark`/`guth-light` in `assets/stylesheets/site.src.css`; daisyUI ist auf die genutzten Komponenten beschränkt (`include:`). Neue daisyUI-Komponente nutzen? Name dort ergänzen (Dateiname der Komponente, z. B. `button` für `btn`).

### Datenschutz / Cookies
Kein Cookie-Banner nötig: keine Tracker, keine externen Schriften, YouTube-Videos und Karte laden erst nach Klick (`data-embed` in `site.js`), Anfragen gehen vorher an keinen Fremdserver. Eine **rechtssichere Datenschutzerklärung** ist trotzdem Pflicht (aktuell Platzhalter `/datenschutz/`, `noindex`).

### Performance (Lighthouse, Mobil-Simulation, mit Textkompression)
Leistung 96 · Barrierefreiheit 100 · Best Practices 100 · SEO 100 · LCP 2,9 s · CLS 0 (Altseite laut PageSpeed: Mobil-Leistung 63, CLS 0,694).
Maßnahmen: Bilder mit festen Maßen, `srcset` (`-640.webp` via `scripts/make_variants.py`), nur das Hero-Foto lädt sofort (`fetchpriority=high`), alle anderen `lazy`; kein Slider, keine JS-Bibliotheken, Animationen per CSS; Schrift vorgeladen; `.htaccess` komprimiert Text.

### SEO
Semantisches HTML5, Title wie Live-Seite (Seitenname • Fahrschule Bochum Uli Guth - Deine Fahrschule in Bochum-Weitmar!), Description der Startseite wie Live, canonical, Open Graph/Twitter, `sitemap.xml`, `robots.txt`, `llms.txt`,
JSON-LD `@graph` mit `DrivingSchool`/`LocalBusiness` (Adresse, Telefon, Öffnungszeiten, Geo), `WebSite`, `WebPage`, `BreadcrumbList`.
Keine Bewertungen und kein `FAQPage`, weil die Altseite weder Bewertungen noch Fragen/Antworten enthält.

## URLs / Weiterleitungen
Alle URLs der Altseite bleiben identisch (Verzeichnis-URLs mit Slash): `/`, `/ueberuns/`, `/ueberuns/preise/`, `/ueberuns/links/`, `/ueberuns/downloads/`, `/galerie/`, `/galerie/bestanden/`, `/galerie/fahrzeuge/`, `/galerie/motorraeder/`, `/galerie/videos/`, `/news/`, `/kontakt/`, `/impressum/`, `/404.html`.
Es sind daher keine Weiterleitungen nötig. Einzige Abweichung: Das Alt-Menü verlinkte `/galerie/bestanden` ohne Slash – das wird vom Webserver auf `/galerie/bestanden/` umgeleitet.

## Offene Punkte
- [ ] **Datenschutzerklärung fehlt** (auch in der Altseite nicht vorhanden); rechtlich nötig, besonders mit Anmeldeformular. `/datenschutz/` ist ein **Entwurf** (`noindex`), der beschreibt, was die Seite technisch tut. Gelb markiert fehlen Hoster, Löschfrist der Logfiles und die Anpassung ans Formular; Text vom Inhaber/Anwalt/Generator prüfen lassen, dann Hinweis und `noindex` entfernen.
- [ ] **Impressum:** „§ 5 TMG“ auf „§ 5 DDG“ geändert, OS-Plattform-Hinweis (Plattform seit 2025 eingestellt) und Google-Fonts-Absatz (Schrift ist jetzt selbst gehostet) entfernt. Offen: Steuernummer ist im Impressum nicht vorgeschrieben (nur USt-IdNr., falls vorhanden) und könnte entfallen; Haftungsausschluss-Text ist Altbestand; Angaben zur Verbraucherstreitbeilegung prüfen.
- [ ] **Entwürfe von Uli prüfen lassen, bevor live:** „Dein erster Fahrtag“ (`data/ablauf.yml`), FAQ-Antworten besonders zu Fahrschulwechsel und Finanzierung (`data/faq.yml`), Voraussetzungen je Klasse (`data/klassen.yml`: BF17, B196, B96, A), Reform 2027 (`data/reform.yml`; Quelle ist eine kommerzielle Seite, gegen Bundesverkehrsministerium/Bundesgesetzblatt prüfen).
- [ ] **Preise für BF17, B196, B96 fehlen** (stehen als „auf Anfrage“); BF17 ist mit Klasse B verknüpft, bitte bestätigen.
- [ ] **Anmeldeformular** (`/anmelden/`) sendet derzeit per `mailto:` an `uli@fahrschuleguth.de` und öffnet nur das Mailprogramm der Besucher. Für echten Versand ein Formular-Skript/-Dienst anbinden (Apache + PHP vorhanden?).
- [ ] Kurzes **Video** (Einsteigen/Fahrstunde) auf der Startseite ergänzen; bis dahin gibt es `/galerie/videos/` (Klick zum Laden).
- [ ] Maskottchen-Quellbild (`bilder/kopf.webp`) ist nur 50 × 50 px; für größere Darstellung neu liefern.
- [ ] Nach dem Livegang echten PageSpeed (mobil) und die Google-Search-Console prüfen, Ranking für „Fahrschule Bochum-Weitmar“ beobachten.
- [ ] **PDFs fehlen**: `/assets/files/checkliste.pdf`, `flyer.pdf`, `fuehrerschein_mit_17_anlage_1.pdf`, `…_2.pdf` sind im Alt-Repo nicht enthalten (kamen aus einem Ordner `statics/files`, der nicht eingecheckt ist). In `source/assets/files/` ablegen.
- [ ] Preisliste trägt „Stand April 2022“ – Aktualität prüfen (Preisaushang).
- [ ] Tippfehler der Altseite bewusst unverändert: „Theorieuntericht“, „Neuste Sena Funk Technik“, „Sebtember 2021“, „Gallerie“.
- [ ] Fotos zeigen erkennbare Fahrschüler, News nennen Vornamen: Einwilligungen prüfen.
- [ ] Alt-Texte der Galerie-Bilder wurden beschreibend ergänzt; „Bestanden“-Bilder haben generische Alt-Texte mit Monat/Jahr.
- [ ] Kein eigenes Logo übernommen (Wortmarke als Text, `favicon.svg` neu); ggf. Original-Logo liefern. OG-Bild ist neu aus einem Foto generiert.
- [ ] Alt-Features nicht übernommen: Header-Slider/Typed-Text, Bilder-Slider (75 Fotos), Material-Icons-Font, Google-Plus/Facebook-App-ID/Twitter-Meta, Leaflet-Karte (jetzt OSM-Einbettung, lädt erst nach Klick), `sitemap_ping`. Videos nutzen `youtube-nocookie.com` und laden erst nach Klick.
- [ ] Facebook-Link `https://www.facebook.com/fahrschuleguth` aus der Alt-Meta als `sameAs`/Footer übernommen – prüfen, ob noch aktuell.
- [ ] Per-Seiten-Meta-Descriptions: Startseite unverändert, Unterseiten neu aus vorhandenen Seitenfakten formuliert (Alt nutzte überall dieselbe).
- [ ] Der `<404>`-Text ist neu (Alt war grafisch); Deployment: `build/` auf den Apache-Webserver (`.htaccess` liegt bei).
