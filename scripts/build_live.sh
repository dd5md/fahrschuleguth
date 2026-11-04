#!/usr/bin/env bash
# Baut die echte Seite (fahrschuleguth.de) ohne Testbanner und mit Indexierung.
set -euo pipefail
cd "$(dirname "$0")/.."
export LANG=C.UTF-8 LC_ALL=C.UTF-8
bundle exec middleman build --clean
echo
echo "Fertig: Live-Version liegt in build/."
