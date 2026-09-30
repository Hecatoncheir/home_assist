#!/usr/bin/env bash
# Собирает образ home_assist-macos.dmg из результата `flutter build macos`:
# внутри приложение и ярлык на «Программы», чтобы перетащить одно в другое.
set -euo pipefail

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cp -R build/macos/Build/Products/Release/home_assist.app "$stage/Home Assist.app"
ln -s /Applications "$stage/Applications"

hdiutil create \
  -volname "Home Assist $(bash packaging/version.sh)" \
  -srcfolder "$stage" \
  -format UDZO \
  -ov home_assist-macos.dmg
