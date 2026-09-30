#!/usr/bin/env bash
# Собирает самораспаковывающийся установщик home_assist-linux-x64.run
# из результата `flutter build linux`. Нужен makeself.
set -euo pipefail

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cp -R build/linux/x64/release/bundle "$stage/bundle"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png "$stage/icon.png"
cp packaging/linux/install.sh "$stage/install.sh"
chmod +x "$stage/install.sh"

makeself --xz "$stage" home_assist-linux-x64.run \
  "Home Assist $(bash packaging/version.sh)" ./install.sh
