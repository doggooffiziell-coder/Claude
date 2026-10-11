#!/usr/bin/env sh
# Baut die eigenständige Seite für GitHub Pages aus der Artifact-Seite.
# ameisen/web/AntPop.html enthält das Spiel, pages-head.html den Dokumentkopf mit App-Symbol.
set -e
cd "$(dirname "$0")"
OUT=../../docs/antpop
mkdir -p "$OUT"
# die eingebetteten Daten-Icons der Artifact-Fassung weglassen, hier gibt es echte Dateien
{ cat pages-head.html; grep -v '^<link rel="icon" type="image/png" href="data:\|^<link rel="apple-touch-icon" href="data:' AntPop.html; printf '\n</body>\n</html>\n'; } > "$OUT/index.html"
cp ../icons/icon_180.png "$OUT/icon-180.png"
cp ../icons/icon_192.png "$OUT/icon-192.png"
cp ../icons/icon_512.png "$OUT/icon-512.png"
echo "docs/antpop/index.html aktualisiert"
