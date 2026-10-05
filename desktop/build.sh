#!/usr/bin/env sh
# Builds the Ragpit desktop app for Windows, Mac and Linux with Electron.
# Output: dist/desktop/Ragpit-Windows.zip, Ragpit-Mac-AppleSilicon.zip,
# Ragpit-Mac-Intel.zip and Ragpit-Linux.zip. The binaries are not kept in git.
set -e
cd "$(dirname "$0")"
../pc/build.sh
rm -rf app && mkdir app
cp ../dist/Ragpit-PC/Ragpit.html ../dist/Ragpit-PC/icon.png app/
npm install --no-audit --no-fund --loglevel=error
OUT=../dist/desktop
rm -rf "$OUT" && mkdir -p "$OUT"
pack() { npx electron-packager . Ragpit --platform="$1" --arch="$2" --out="$OUT/build" --overwrite --asar \
  --ignore='^/build\.sh$' --ignore='^/LIESMICH' --ignore='^/\.gitignore$' --app-copyright="Ragpit" --app-version=1.0.0 >/dev/null; }
zipit() { (cd "$OUT/build" && zip -qry -X "../$2" "$1") ; }
pack win32 x64 && cp LIESMICH-Desktop.txt "$OUT/build/Ragpit-win32-x64/LIESMICH.txt" && zipit Ragpit-win32-x64 Ragpit-Windows.zip
pack linux x64 && cp LIESMICH-Desktop.txt "$OUT/build/Ragpit-linux-x64/LIESMICH.txt" && zipit Ragpit-linux-x64 Ragpit-Linux.zip
pack darwin arm64 && cp LIESMICH-Desktop.txt "$OUT/build/Ragpit-darwin-arm64/LIESMICH.txt" && zipit Ragpit-darwin-arm64 Ragpit-Mac-AppleSilicon.zip
pack darwin x64 && cp LIESMICH-Desktop.txt "$OUT/build/Ragpit-darwin-x64/LIESMICH.txt" && zipit Ragpit-darwin-x64 Ragpit-Mac-Intel.zip
ls -la "$OUT"
