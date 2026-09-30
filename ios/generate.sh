#!/bin/sh
# Erzeugt Paketlotse.xcodeproj neu – nach jedem `git pull` ausführen (neue Dateien!).
set -e
cd "$(dirname "$0")"
if [ ! -f Config/Secrets.xcconfig ]; then
  cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
  echo "⚠️  Config/Secrets.xcconfig angelegt – bitte DEVELOPMENT_TEAM eintragen und erneut ausführen."
fi
xcodegen generate
