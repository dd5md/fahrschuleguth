#!/usr/bin/env bash
# Baut die Seite als Testversion (für test.fahrschuleguth.de): gesperrt für Suchmaschinen, mit Banner.
# Danach den INHALT von build/ auf den Server (Startverzeichnis der Subdomain) hochladen.
set -euo pipefail
cd "$(dirname "$0")/.."
export LANG=C.UTF-8 LC_ALL=C.UTF-8
NOINDEX=1 SITE_URL="${SITE_URL:-https://test.fahrschuleguth.de}" bundle exec middleman build --clean
echo
echo "Fertig: Testversion liegt in build/ (Banner + noindex aktiv)."
