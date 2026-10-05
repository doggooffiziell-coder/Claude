#!/usr/bin/env sh
# Builds the small Ragpit desktop app with Neutralino: the system's own web
# view shows the PC version, so each package is only a few MB.
# Output: dist/desktop-lite/Ragpit-Lite-Windows.zip, -Mac.zip, -Linux.zip.
set -e
cd "$(dirname "$0")"
V=6.3.0
../pc/build.sh
rm -rf resources && mkdir resources
cp ../dist/Ragpit-PC/Ragpit.html ../dist/Ragpit-PC/icon.png resources/
if [ ! -f bin/neutralino-win_x64.exe ]; then
  mkdir -p bin
  curl -sSL -o bin/neu.zip "https://github.com/neutralinojs/neutralinojs/releases/download/v$V/neutralinojs-v$V.zip"
  (cd bin && unzip -qo neu.zip && rm neu.zip)
fi
npx -y @neutralinojs/neu@11 build >/dev/null 2>&1
OUT=../dist/desktop-lite
rm -rf "$OUT" && mkdir -p "$OUT"
# Neutralino reads resources.neu from the current folder. A double click on
# the Mac or on Linux starts elsewhere, so a tiny starter changes into the
# app's folder first. On Windows the exe starts in its own folder anyway.
starter() { printf '#!/bin/sh\ncd "$(dirname "$0")/%s" && exec ./ragpit-bin "$@"\n' "$2" > "$1"; chmod +x "$1"; }

D="$OUT/Ragpit-Windows"; mkdir -p "$D"
cp dist/Ragpit/Ragpit-win_x64.exe "$D/Ragpit.exe"; cp dist/Ragpit/resources.neu "$D/"
sed 's/$/\r/' LIESMICH-Lite.txt > "$D/LIESMICH.txt"
(cd "$OUT" && zip -qry -X Ragpit-Lite-Windows.zip Ragpit-Windows)

D="$OUT/Ragpit-Linux"; mkdir -p "$D/data"
cp dist/Ragpit/Ragpit-linux_x64 "$D/data/ragpit-bin"; chmod +x "$D/data/ragpit-bin"; cp dist/Ragpit/resources.neu "$D/data/"
starter "$D/Ragpit" data
cp LIESMICH-Lite.txt "$D/LIESMICH.txt"
(cd "$OUT" && zip -qry -X Ragpit-Lite-Linux.zip Ragpit-Linux)

# The Mac gets a real app bundle that starts the universal binary.
A="$OUT/Ragpit-Mac/Ragpit.app/Contents"; mkdir -p "$A/MacOS" "$A/Resources"
cp dist/Ragpit/Ragpit-mac_universal "$A/MacOS/ragpit-bin"; chmod +x "$A/MacOS/ragpit-bin"
cp dist/Ragpit/resources.neu "$A/MacOS/"
starter "$A/MacOS/Ragpit" .
cp LIESMICH-Lite.txt "$OUT/Ragpit-Mac/LIESMICH.txt"
cat > "$A/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Ragpit</string>
<key>CFBundleDisplayName</key><string>Ragpit</string>
<key>CFBundleIdentifier</key><string>de.ragpit.game</string>
<key>CFBundleVersion</key><string>1.0.0</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleExecutable</key><string>Ragpit</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>10.15</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
(cd "$OUT" && zip -qry -X Ragpit-Lite-Mac.zip Ragpit-Mac)
ls -la "$OUT"/*.zip
