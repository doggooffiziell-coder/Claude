#!/usr/bin/env sh
# Baut die Web-Version für das Artefakt nach dist/verwuchert-web/.
# Braucht Godot 4.4.1 mit der Vorlage web_nothreads_release.zip.
# web/page.html ist die Seite um das Spiel. Sie lädt data-engine.wasm (gepackte Engine)
# und data-pck.wasm (Spieldaten), weil Artefakte nur bestimmte Dateitypen ausliefern.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
OUT=../dist/verwuchert-web
rm -rf "$OUT" && mkdir -p "$OUT"
"$GODOT" --headless --path . --export-release "Web" "$OUT/verwuchert.html"
gzip -9 -c "$OUT/verwuchert.wasm" > "$OUT/data-engine.wasm"
mv "$OUT/verwuchert.pck" "$OUT/data-pck.wasm"
rm -f "$OUT/verwuchert.wasm" "$OUT/verwuchert.html" "$OUT"/*.png
SIZE=$(wc -c < "$OUT/data-pck.wasm" | tr -d ' ')
sed "s/\"verwuchert.pck\": [0-9]*/\"verwuchert.pck\": $SIZE/" web/page.html > "$OUT/index.html"
cp docs/menu.png "$OUT/poster.png"
echo "Fertig: $OUT"
