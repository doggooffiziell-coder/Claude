#!/bin/sh
# Startet Ragpit in einem eigenen Fenster ohne Adressleiste.
# Ohne Chrome oder Chromium oeffnet der normale Browser das Spiel.
cd "$(dirname "$0")"
GAME="$(pwd)/Ragpit.html"
PROFILE="${XDG_CONFIG_HOME:-$HOME/.config}/ragpit/browser"
for B in google-chrome chromium chromium-browser microsoft-edge brave-browser; do
  if command -v "$B" >/dev/null 2>&1; then
    exec "$B" --app="file://$GAME" --start-fullscreen --user-data-dir="$PROFILE"
  fi
done
xdg-open "$GAME"
