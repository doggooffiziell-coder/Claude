#!/bin/sh
# Startet Ragpit in einem eigenen Fenster ohne Adressleiste.
# Ohne Chrome oder Edge oeffnet der normale Browser das Spiel.
cd "$(dirname "$0")"
GAME="$(pwd)/Ragpit.html"
PROFILE="$HOME/Library/Application Support/Ragpit/browser"
for APP in "Google Chrome" "Microsoft Edge" "Brave Browser" "Chromium"; do
  if [ -d "/Applications/$APP.app" ]; then
    open -na "$APP" --args --app="file://$GAME" --start-fullscreen --user-data-dir="$PROFILE"
    exit 0
  fi
done
open "$GAME"
