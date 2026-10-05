#!/usr/bin/env sh
# Builds the PC version: a folder with the game page, the icon, starters for
# Windows, Mac and Linux and a short guide, packed as docs/Ragpit-PC.zip.
set -e
cd "$(dirname "$0")"
OUT=../dist/Ragpit-PC
rm -rf ../dist
mkdir -p "$OUT"
{ cat head.html; cat ../web/ragpit.html; printf '\n</body>\n</html>\n'; } > "$OUT/Ragpit.html"
cp ../docs/icon-180.png "$OUT/icon.png"
# Windows needs CRLF line ends in .bat and .txt files.
sed 's/$/\r/' "Ragpit starten (Windows).bat" > "$OUT/Ragpit starten (Windows).bat"
sed 's/$/\r/' LIESMICH.txt > "$OUT/LIESMICH.txt"
cp "Ragpit starten (Mac).command" ragpit-linux.sh "$OUT/"
chmod +x "$OUT/Ragpit starten (Mac).command" "$OUT/ragpit-linux.sh"
(cd ../dist && rm -f ../docs/Ragpit-PC.zip && zip -qr -X ../docs/Ragpit-PC.zip Ragpit-PC)
echo "docs/Ragpit-PC.zip updated"
